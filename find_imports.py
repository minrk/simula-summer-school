import ast
import operator
import pathlib
from collections import Counter
from pprint import pprint

import click
import nbformat


class ImportCollector(ast.NodeVisitor):
    def __init__(self):
        self.imports = Counter()

    def _collect(self, name):
        names = [name]
        while "." in name:
            name, _ = name.rsplit(".", 1)
            names.append(name)
        self.imports.update(names)

    def visit_Import(self, node):
        for alias in node.names:
            self._collect(alias.name)
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        for alias in node.names:
            self._collect(f"{node.module}.{alias.name}")
        self.generic_visit(node)


@click.command()
@click.argument("path", type=click.Path(exists=True), required=True)
def find_imports(path):
    from IPython.core.inputtransformer2 import TransformerManager

    tm = TransformerManager()
    collector = ImportCollector()
    for nb_file in pathlib.Path(path).glob("**/*.ipynb"):
        with nb_file.open("r") as f:
            nb = nbformat.read(f, as_version=4)
        for cell in nb.cells:
            if cell.cell_type == "code":
                source = tm.transform_cell(cell.source)
                try:
                    node = ast.parse(source)
                except SyntaxError:
                    # invalid cell
                    # e.g. cell with magics
                    pass
                else:
                    collector.visit(node)

    for py_file in pathlib.Path(path).glob("**/*.py"):
        with py_file.open("r") as f:
            source = f.read()
            try:
                node = ast.parse(source)
            except SyntaxError:
                # invalid cell
                # e.g. cell with magics
                pass
            else:
                collector.visit(node)

    print("All counts")
    pprint(collector.imports)
    print("Top-level packages")
    for mod, count in sorted(
        collector.imports.items(),
        key=lambda x: (x[1], len(x[0]), x[0]),
        reverse=True,
    ):
        if "." not in mod:
            print(f"{mod:20}: {count:3}")


if __name__ == "__main__":
    find_imports()
