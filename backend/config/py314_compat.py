"""
Python 3.14 compatibility for Django 4.2 template contexts.

Django 4.2 uses copy(super()) in BaseContext.__copy__, which breaks on
Python 3.14 where super objects are shallow-copied differently.
"""

import sys
from copy import copy


def apply():
    if sys.version_info < (3, 14):
        return

    from django.template import context as template_context

    def basecontext_copy(self):
        duplicate = template_context.BaseContext()
        duplicate.__class__ = self.__class__
        duplicate.__dict__ = copy(self.__dict__)
        duplicate.dicts = self.dicts[:]
        return duplicate

    template_context.BaseContext.__copy__ = basecontext_copy
