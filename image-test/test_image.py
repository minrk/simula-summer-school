import os

import pytest


def test_0_puller():
    import pull_server_ext

    pull_server_ext.pull_everything()
    assert os.path.exists("SSCP_2021_lectures")


def test_puller_ext():
    from jupyter_core.paths import jupyter_config_path
    from jupyter_server.extension.manager import ExtensionManager
    from jupyter_server.extension.config import ExtensionConfigManager

    m = ExtensionManager(
        config_manager=ExtensionConfigManager(read_config_paths=jupyter_config_path())
    )
    for name, ext in m.extensions.items():
        print(f"Validating extension {name}")
        # workaround
        for ep_name, extension_point in ext.extension_points.items():
            print(f"Validating extension {name}.{ep_name}")
            assert extension_point.validate() in {None, True}
        ext.validate()
    assert "pull_server_ext" in m.extensions


def test_dolfin():
    from dolfin import UnitIntervalMesh, FiniteElement, FunctionSpace, interval

    mesh = UnitIntervalMesh(20)
    elem = FiniteElement("CG", interval, 1)
    W = FunctionSpace(mesh, elem)


def test_neuron():
    from neuron import h, rxd


@pytest.mark.parametrize(
    "notebook",
    [
        "SSCP_2021_lectures/Stream 3 (Neural Electrophysiology)/Exercise_20C_NEURON_RxD/NEURON_RxD_exercise2.ipynb",
    ],
)
def test_notebook(notebook):
    import nbformat
    from nbconvert.preprocessors import ExecutePreprocessor

    with open(notebook) as f:
        nb = nbformat.read(f, as_version=4)
    p = ExecutePreprocessor()
    p.preprocess(nb)
