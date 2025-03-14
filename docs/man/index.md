---
layout: default
title: rpm.org - RPM Manual Pages
---

{% assign tools = site.man      | where: 'category', 'tool' %}
{% assign plugins = site.man    | where: 'category', 'plugin' %}

# RPM Manual Pages

## Tools

{% for page in tools -%}
- [{{ page.name }}]({{ page.filename }})
{% endfor %}

## Plugins

{% for page in plugins -%}
- [{{ page.name }}]({{ page.filename }})
{% endfor %}
