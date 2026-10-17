import numpy as np
import pytest

from occfringe.diameter import Event, EventConfig, EventModel, run_case, truth_params
from occfringe.nircam import saturation_mag

MAG = saturation_mag("F150W", "SUB64P") + 2


@pytest.fixture(scope="module")
def model():
    cfg = EventConfig(radius=10e3, distance_au=40, speed=10e3, impact=5e3, star_uas=10,
                      filter="F150W", subarray="SUB64P", mag_ab=MAG)
    return EventModel(cfg)


def test_library_reproduces_node_radius(model):
    th = truth_params(model.cfg)
    ev = Event(model, 10e3, 5e3, MAG, rng=np.random.default_rng(0))
    assert th[0] == pytest.approx(np.sqrt(10e3 ** 2 - 5e3 ** 2))
    assert np.all(np.isfinite(ev.clean)) and ev.clean.min() < 0.05 and ev.clean.max() > 1.1


def test_fits_recover_radius_and_rank_models(model):
    row = run_case(model, 10e3, 5e3, MAG, rng=np.random.default_rng(1))
    R = model.cfg.radius
    assert abs(row["circle_R_fit"] - R) < 5 * row["circle_sigma_R"]
    assert row["circle_sigma_R"] == pytest.approx(row["sigma_R_fisher"], rel=0.3)
    assert row["dchi2_knife_expected"] > 25 and row["dchi2_geometric_expected"] > row["dchi2_knife_expected"]
    assert row["circle_chi2"] < row["dof"] + 5 * np.sqrt(2 * row["dof"])
    assert row["sigma_R_fisher_vprior"] > row["sigma_R_fisher"]
    assert row["geometric_sigma_R_fisher"] > row["sigma_R_fisher"]


def test_saturated_case_is_flagged(model):
    row = run_case(model, 10e3, 5e3, MAG - 3)
    assert row["nircam_saturated"] and row["n_samples"] == 0
