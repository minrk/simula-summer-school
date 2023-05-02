import os

import pytest

lectures_dir = "SSCP_2023_lectures"


@pytest.fixture(scope="session")
def needs_puller():
    """Some tests need the puller to have run"""
    if not os.path.exists(lectures_dir):
        test_puller()


def test_puller_ext():
    from jupyter_core.paths import jupyter_config_path
    from jupyter_server.extension.config import ExtensionConfigManager
    from jupyter_server.extension.manager import ExtensionManager

    m = ExtensionManager(
        config_manager=ExtensionConfigManager(read_config_path=jupyter_config_path())
    )
    for name, ext in m.extensions.items():
        print(f"Validating extension {name}")
        # workaround
        for ep_name, extension_point in ext.extension_points.items():
            print(f"Validating extension {name}.{ep_name}")
            assert extension_point.validate() in {None, True}
        ext.validate()
    assert "pull_server_ext" in m.extensions


def test_puller():
    import pull_server_ext

    pull_server_ext.pull_everything()
    assert os.path.exists(lectures_dir)


def test_torch():
    import torch


def test_dolfin():
    from dolfin import FiniteElement, FunctionSpace, UnitIntervalMesh, interval

    mesh = UnitIntervalMesh(20)
    elem = FiniteElement("CG", interval, 1)
    W = FunctionSpace(mesh, elem)


def test_neuron():
    from neuron import h, rxd  # noqa


@pytest.mark.parametrize(
    "notebook",
    [
        f"{lectures_dir}/L14 (FEniCS Mechanics)/L13_solved.ipynb",
        f"{lectures_dir}/Stream 1 (Cardiac Mechanics)/L19-20/L20-solved.ipynb",
    ],
)
def test_notebook(notebook, needs_puller):
    import nbformat
    from nbconvert.preprocessors import ExecutePreprocessor

    with open(notebook) as f:
        nb = nbformat.read(f, as_version=4)
    p = ExecutePreprocessor()
    p.preprocess(nb)
