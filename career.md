---
layout: page
title: Career
permalink: /career/
no_duoshuo: true
---

<div class="posts">
  {% for post in site.posts %}
    {% if post.categories contains "career" %}
      <div class="post">
        <a href="{{ post.url | prepend: site.baseurl }}" class="post-link">
          <p class="post-meta">{{ post.date | date: "%m 月 %d日, %Y" }}</p>
          <h3 class="h2 post-title">{{ post.title }}</h3>
          {% if post.summary %}
            <p class="post-summary">{{ post.summary }}</p>
          {% endif %}
        </a>
      </div>
    {% endif %}
  {% endfor %}
</div>
