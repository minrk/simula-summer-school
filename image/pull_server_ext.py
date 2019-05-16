"""
A severely stripped-down version of data-8/nbpuller
"""

import requests
from tornado.log import app_log

from nbgitpuller.pull import GitPuller

def pull_repo(repo_url):

    branch_name = 'master'
    repo_dir = repo_url.rsplit('/', 1)[-1]
    if repo_dir.endswith('.git'):
        repo_dir = repo_dir[:-4]

    app_log.info("Pulling %s", repo_url)
    gp = GitPuller(repo_url, branch_name, repo_dir)
    for line in gp.pull():
        app_log.info(line.rstrip('\n'))


def pull_everything():
    r = requests.get('https://raw.githubusercontent.com/minrk/simula-summer-school/2019/repos.txt')
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
    ThreadPoolExecutor(1).submit(pull_everything)

