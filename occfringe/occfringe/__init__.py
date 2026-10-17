"""Fresnel diffraction light curves for small-body stellar occultations.

Python port of the OOSSIM ``cdiffracSim`` diffraction model (Bickerton 2007)
extended to geometric occultations and JWST/NIRCam photometry.
"""

from . import bandpass, constants, diameter, edge, fresnel, legacy, lightcurve, nircam, shapes, star

__all__ = ["bandpass", "constants", "diameter", "edge", "fresnel", "legacy", "lightcurve", "nircam", "shapes",
           "star"]
__version__ = "0.1.0"
