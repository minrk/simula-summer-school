"""
A severely stripped-down version of data-8/nbpuller
"""
import os

import git
import requests
from tornado.log import app_log

from nbpuller.pull_from_remote import (
    _reset_deleted_files,
    _pull_and_resolve_conflicts,
)

def _make_commit_if_dirty(repo, repo_dir):
    """
    Makes a commit with message 'WIP' if there are changes.
    
    from nbpuller
    """
    if repo.is_dirty():
        git_cli = repo.git
        git_cli.add('-A')

        app_log.info("Adding files: %s", git_cli.status())

        git_cli.commit('-m', 'WIP')

        app_log.info('Made WIP commit')

def pull_repo(repo_url):

    branch_name = 'master'
    repo_dir = repo_url.rsplit('/', 1)[-1]
    if repo_dir.endswith('.git'):
        repo_dir = repo_dir[:-4]

    if not os.path.exists(repo_dir):
        app_log.info("Cloning %s into %s", repo_url, repo_dir)
        git.Repo.clone_from(repo_url, repo_dir)
    else:
        app_log.info("Updating %s", repo_url)
    repo = git.Repo(repo_dir)

    _reset_deleted_files(repo, branch_name)
    _make_commit_if_dirty(repo, repo_dir)

    _pull_and_resolve_conflicts(repo, branch_name)


def pull_everything():
    r = requests.get('https://raw.githubusercontent.com/minrk/simula-summer-school/master/repos.txt')
    r.raise_for_status()
    for line in r.text.splitlines():
        line = line.strip()
        if line.startswith('#'):
            continue
        if not line:
            continue
        repo_url = line
        try:
            pull_repo(repo_url)
        except Exception:
            app_log.exception("Failed to pull repo %s", repo_url)


from concurrent.futures import ThreadPoolExecutor

from notebook.utils import url_path_join
from notebook.base.handlers import IPythonHandler
from tornado.web import authenticated
from tornado.gen import coroutine

class PullEverythingHandler(IPythonHandler):
    
    @property
    def pull_pool(self):
        if 'pull_pool' not in self.settings:
            self.settings['pull_pool'] = ThreadPoolExecutor(1)
        return self.settings['pull_pool']

    @authenticated
    @coroutine
    def post(self):
        self.log.info("Updating all repos")
        yield self.pull_pool.submit(pull_everything)
        self.log.info("Updated all repos")


def setup_handlers(web_app):
    base_url = web_app.settings.get('base_url', '/')
    web_app.add_handlers('.*', [
        (url_path_join(base_url, 'api/pull-repos'), PullEverythingHandler),
    ])


def load_jupyter_server_extension(nbapp):
    setup_handlers(nbapp.web_app)
    pull_everything()

