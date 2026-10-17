"""Can ingress/egress diffraction fringes measure a TNO's diameter from a single NIRCam chord?

A central question is what the fringes add beyond chord timing.  Each event
is fit with three models sharing the parameters

    L   chord half-length [m],
    D   R - L >= 0, so the body radius is R = L + D and the impact parameter
        b = sqrt(R^2 - L^2),
    t0  mid-event time [s],
    f0  unocculted flux,

and a known shadow speed v:

``circle``     exact circular-limb diffraction (the physical model);
``knife``      straight-edge diffraction crossed at the local limb angle,
               I = K(s (|x| - L)) with s = L / R: fringe spacing measures the
               crossing angle, but limb curvature is ignored;
``geometric``  the same geometry with a sharp edge, smoothed only by the
               stellar disk and the exposure (chord timing with no fringes).

The radius is constrained through D, i.e. through how obliquely the chord
crosses the limb (and, in ``circle``, through curvature), which only
diffraction fringes or a resolved stellar disk can reveal.  For each model we
report sigma_R from the least-squares covariance, and the chi^2 penalty of the
simpler models relative to ``circle``.
"""

from dataclasses import asdict, dataclass

import numpy as np
from scipy.interpolate import CubicSpline
from scipy.optimize import least_squares

from .constants import AU, UAS, fresnel_scale
from .edge import geometric_edge_profile, knife_edge_profile
from .lightcurve import exposure_average, n_substeps, radial_profile
from .nircam import NIRCamSetup
from .star import StellarDisk

MODELS = ("circle", "knife", "geometric")


@dataclass
class EventConfig:
    radius: float                 # body radius [m]
    distance_au: float            # occulter distance [AU]
    speed: float                  # shadow speed [m/s]
    impact: float                 # impact parameter b [m]
    star_uas: float               # stellar angular radius [micro-arcsec]
    filter: str = "F200W"
    subarray: str = "SUB64P"
    mag_ab: float = 13.0
    teff: float = 5800.0
    limb_darkening: float = 0.0
    window_F: float = 10.0        # half-width of the diffraction window, in Fresnel scales
    baseline: float = 2.0         # extra time observed before ingress and after egress [s]
    flat_noise: float = 1e-3      # fractional flat-field/jitter error per sample

    @property
    def z(self):
        return self.distance_au * AU

    @property
    def star_radius(self):
        """Projected stellar radius at the occulter [m]."""
        return self.star_uas * UAS * self.z


class EventModel:
    """Light-curve models for one body/star/filter combination (shared by all speeds, impacts, magnitudes).

    The circular-limb model interpolates, in 1/R, a library of limb profiles
    computed at ``n_nodes`` radii within +/- ``span`` of the true radius.
    """

    def __init__(self, cfg, span=0.35, n_nodes=None):
        self.cfg = cfg
        self.setup = NIRCamSetup(cfg.filter, cfg.subarray, cfg.mag_ab)
        self.band = self.setup.bandpass(cfg.teff, cfg.window_F)
        z = cfg.z
        self.F_min = float(fresnel_scale(self.band.lam_min, z))
        self.F_max = float(fresnel_scale(self.band.lam_max, z))
        self.F_mid = float(fresnel_scale(self.band.mean, z))
        self.disk = StellarDisk.for_fresnel_scale(cfg.star_radius, self.F_min, limb_darkening=cfg.limb_darkening)
        self.half = cfg.window_F * self.F_max + self.disk.radius
        self.du = self.F_min / 20.0
        self.u = np.arange(-self.half, self.half + self.du, self.du)

        R = cfg.radius
        if n_nodes is None:
            n_nodes = 7 if R < 20.0 * self.F_mid else 5
        q = np.linspace(1.0 / (R * (1.0 + span)), 1.0 / (R * (1.0 - span)), n_nodes)
        self.q_range = (q[0], q[-1])
        prof = [radial_profile(1.0 / qj, z, self.band, self.disk, r_out=np.abs(1.0 / qj + self.u)).I for qj in q]
        self.library = CubicSpline(q, np.array(prof), axis=0)
        self.knife = knife_edge_profile(z, self.band, self.disk, cfg.window_F)
        self.geometric = geometric_edge_profile(self.disk.radius, cfg.limb_darkening)

    def circle_profile(self, R):
        q = np.clip(1.0 / R, *self.q_range)
        return self.library(q)

    def curvature_signal(self):
        """max |I_circle(R + u) - K(u)| at the true radius, outside the central half of the shadow."""
        sel = self.u > -0.5 * self.cfg.radius
        return float(np.max(np.abs(self.circle_profile(self.cfg.radius)[sel] - self.knife(self.u[sel]))))

    def flux(self, model, theta, t_a, t_b, speed, n_sub):
        L, D, t0, f0 = theta
        R = L + D
        s = L / R
        if model == "circle":
            b = np.sqrt(max(R * R - L * L, 0.0))
            pu = self.circle_profile(R)
            fn = lambda t: np.interp(np.hypot(speed * (t - t0), b) - R, self.u, pu, left=0.0, right=1.0)  # noqa: E731
        elif model == "knife":
            fn = lambda t: self.knife(s * (np.abs(speed * (t - t0)) - L))  # noqa: E731
        elif model == "geometric":
            fn = lambda t: self.geometric(s * (np.abs(speed * (t - t0)) - L))  # noqa: E731
        else:
            raise ValueError(model)
        return f0 * exposure_average(fn, t_a, t_b, n_sub)


def truth_params(cfg):
    L = np.sqrt(cfg.radius ** 2 - cfg.impact ** 2)
    return np.array([L, cfg.radius - L, 0.0, 1.0])


class Event:
    """One simulated observation: sampling, noise model, and fits."""

    def __init__(self, model, speed, impact, mag_ab, rng=None, phase=None, truth_profile=None):
        """``truth_profile`` (a :class:`~occfringe.lightcurve.Profile` of intensity vs x = v t
        along the chord) replaces the circular model as the source of the simulated data."""
        self.model = model
        self.cfg = cfg = EventConfig(**{**asdict(model.cfg), "speed": speed, "impact": impact, "mag_ab": mag_ab})
        self.setup = NIRCamSetup(cfg.filter, cfg.subarray, mag_ab, flat_noise=cfg.flat_noise)
        self.truth = truth_params(cfg)
        self.rng = np.random.default_rng() if rng is None else rng
        self.n_sub = n_substeps(speed, self.setup.t_frame, model.F_min)
        if self.setup.saturated:
            self.t_a = self.t_b = np.empty(0)
            return
        L = self.truth[0]
        x_max = np.sqrt((cfg.radius + model.half) ** 2 - cfg.impact ** 2)
        if truth_profile is not None:
            x_max = max(x_max, np.abs(truth_profile.x).max())
        span = x_max / speed + cfg.baseline
        cycle = (self.setup.ngroups + 1) * self.setup.t_frame
        ph = self.rng.uniform(0.0, cycle) if phase is None else phase
        self.t_a, self.t_b = self.setup.sample_intervals(-span, span, phase=ph)
        if truth_profile is None:
            self.clean = self.predict("circle", self.truth)
        else:
            self.clean = exposure_average(lambda t: truth_profile(speed * t), self.t_a, self.t_b, self.n_sub)
        self.sigma = self.setup.sigma(self.clean)
        self.data = self.clean + self.sigma * self.rng.standard_normal(self.clean.size)
        self.L_true = L

    def predict(self, model, theta, speed=None):
        speed = self.cfg.speed if speed is None else speed
        return self.model.flux(model, theta, self.t_a, self.t_b, speed, self.n_sub)

    def _steps(self):
        F = self.model.F_min
        return np.array([0.05 * F, 0.05 * F, 0.05 * F / self.cfg.speed, 1e-3])

    def jacobian(self, model, theta):
        """Finite-difference Jacobian of the sigma-normalised model (one-sided where D would go negative)."""
        h = self._steps()
        cols = []
        for k in range(4):
            tp = theta.copy()
            tm = theta.copy()
            tp[k] += h[k]
            if k == 1 and theta[1] - h[1] < 0.0:
                cols.append((self.predict(model, tp) - self.predict(model, theta)) / h[k])
                continue
            tm[k] -= h[k]
            cols.append((self.predict(model, tp) - self.predict(model, tm)) / (2 * h[k]))
        return np.column_stack(cols) / self.sigma[:, None]

    @staticmethod
    def sigma_R(jac):
        """sigma of R = L + D from J^T J (inf if R is unconstrained)."""
        fisher = jac.T @ jac
        g = np.array([1.0, 1.0, 0.0, 0.0])
        try:
            cov = np.linalg.inv(fisher)
        except np.linalg.LinAlgError:
            return np.inf
        var = g @ cov @ g
        return float(np.sqrt(var)) if var > 0 and np.isfinite(var) else np.inf

    def fisher_sigma_R(self, model="circle", speed_prior=0.0):
        """Fisher sigma_R at the true parameters, as if the data followed ``model`` exactly.

        ``speed_prior`` > 0 adds the shadow speed as a fifth parameter with a
        Gaussian prior of that fractional width (fringe timescales constrain
        only v times the crossing angle).
        """
        jac = self.jacobian(model, self.truth)
        if speed_prior <= 0.0:
            return self.sigma_R(jac)
        v = self.cfg.speed
        h = 1e-4 * v
        dv = (self.predict(model, self.truth, v + h) - self.predict(model, self.truth, v - h)) / (2 * h) / self.sigma
        fisher = np.column_stack([jac, dv]).T @ np.column_stack([jac, dv])
        fisher[4, 4] += 1.0 / (speed_prior * v) ** 2
        try:
            cov = np.linalg.inv(fisher)
        except np.linalg.LinAlgError:
            return np.inf
        var = cov[0, 0] + cov[1, 1] + 2 * cov[0, 1]
        return float(np.sqrt(var)) if var > 0 and np.isfinite(var) else np.inf

    def fit(self, model, data=None):
        """Least-squares fit of ``model``; returns (theta, chi2, sigma_R)."""
        data = self.data if data is None else data
        resid = lambda th: (data - self.predict(model, th)) / self.sigma  # noqa: E731
        jac = lambda th: -self.jacobian(model, th)  # noqa: E731
        lo = np.array([0.05 * self.truth[0], 0.0, -np.inf, 0.0])
        hi = np.array([np.inf, np.inf, np.inf, np.inf])
        best = None
        starts = [self.truth.copy()]
        alt = self.truth.copy()
        alt[1] = 0.5 * self.truth[1] if self.truth[1] > 0 else 0.1 * self.truth[0]
        starts.append(alt)
        for x0 in starts:
            res = least_squares(resid, x0, jac=jac, bounds=(lo, hi), x_scale=self._steps() * 20, method="trf")
            chi2 = float(np.sum(res.fun ** 2))
            if best is None or chi2 < best[1]:
                best = (res.x, chi2)
        theta, chi2 = best
        return theta, chi2, self.sigma_R(self.jacobian(model, theta))


def run_case(model, speed, impact, mag_ab, rng=None, phase=None, speed_prior=0.01):
    """Simulate one event and fit all three models; returns a flat dict for the results table.

    Columns (R = true radius):

    * ``sigma_R_fisher``: circular-limb model, speed known;
      ``sigma_R_fisher_vprior``: same with a ``speed_prior`` fractional speed uncertainty;
    * ``knife_sigma_R_fisher`` / ``geometric_sigma_R_fisher``: information if the light
      curve had straight-edge fringes / no fringes at all (chord timing only);
    * ``<model>_R_fit``, ``<model>_sigma_R``, ``<model>_chi2``: fits to one noisy realisation;
    * ``knife_bias_sigma``: (knife R_fit - R) / sigma, the bias from ignoring curvature;
    * ``dchi2_<model>`` and ``dchi2_<model>_expected``: chi^2 penalty relative to the
      circular model, for the noisy data and for noiseless data.
    """
    ev = Event(model, speed, impact, mag_ab, rng=rng, phase=phase)
    cfg = ev.cfg
    row = dict(asdict(cfg))
    row.update(F_mid=model.F_mid, R_over_F=cfg.radius / model.F_mid, Rstar_m=model.disk.radius,
               Rstar_over_F=model.disk.radius / model.F_mid, n_lambda=model.band.lam.size,
               curvature_signal=model.curvature_signal(), **{f"nircam_{k}": v for k, v in ev.setup.summary().items()
                                                              if k in ("ngroups", "saturated", "snr_per_sample",
                                                                       "duty_cycle", "t_frame")})
    if ev.setup.saturated:
        row.update(n_samples=0)
        return row
    row["n_samples"] = int(ev.t_a.size)
    row["speed_prior"] = speed_prior
    row["sigma_R_fisher"] = ev.fisher_sigma_R("circle")
    row["frac_sigma_R_fisher"] = row["sigma_R_fisher"] / cfg.radius
    row["sigma_R_fisher_vprior"] = ev.fisher_sigma_R("circle", speed_prior=speed_prior)
    row["frac_sigma_R_fisher_vprior"] = row["sigma_R_fisher_vprior"] / cfg.radius
    for m in ("knife", "geometric"):
        row[f"{m}_sigma_R_fisher"] = ev.fisher_sigma_R(m)
        row[f"frac_{m}_sigma_R_fisher"] = row[f"{m}_sigma_R_fisher"] / cfg.radius
    chi2 = {}
    for m in MODELS:
        theta, c2, sR = ev.fit(m)
        R_fit = theta[0] + theta[1]
        chi2[m] = c2
        row[f"{m}_R_fit"] = R_fit
        row[f"{m}_sigma_R"] = sR
        row[f"{m}_chi2"] = c2
        _, c2_clean, _ = ev.fit(m, data=ev.clean)
        row[f"{m}_chi2_noiseless"] = c2_clean
    row["circle_at_library_edge"] = not (model.q_range[0] < 1.0 / row["circle_R_fit"] < model.q_range[1])
    row["knife_bias_sigma"] = (row["knife_R_fit"] - cfg.radius) / row["knife_sigma_R"]
    for m in ("knife", "geometric"):
        row[f"dchi2_{m}"] = chi2[m] - chi2["circle"]
        row[f"dchi2_{m}_expected"] = row[f"{m}_chi2_noiseless"] - row["circle_chi2_noiseless"]
    row["dof"] = row["n_samples"] - 4
    return row
