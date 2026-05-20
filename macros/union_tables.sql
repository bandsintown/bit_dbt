gene{% macro union_tables(tables, exclude_columns=[]) %}

    {% for table in tables %}

        select
            {% for col in adapter.get_columns_in_relation(table) %}
                {% if col.name not in exclude_columns %}
                    {{ col.name }}{% if not loop.last %},{% endif %}
                {% endif %}
            {% endfor %}
        from {{ table }}

        {% if not loop.last %}
        union all
        {% endif %}

    {% endfor %}

{% endmacro %}

