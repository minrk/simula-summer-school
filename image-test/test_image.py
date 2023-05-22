import os

import nbformat
import pytest
from nbconvert.preprocessors import ExecutePreprocessor

lectures_dir = "simber-workshop-2023"


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


def test_mps():
    import mps  # noqa


@pytest.mark.parametrize(
    "notebook",
    [
        "download_data.ipynb",
        "read_data.ipynb",
        "analyze_trace.ipynb",
        "motion.ipynb",
        "tpe.ipynb",
    ],
)
def test_notebook(notebook, needs_puller):
    with open(os.path.join(lectures_dir, notebook)) as f:
        nb = nbformat.read(f, as_version=4)
    p = ExecutePreprocessor()
    p.preprocess(nb, resources={"metadata": {"path": lectures_dir}})
