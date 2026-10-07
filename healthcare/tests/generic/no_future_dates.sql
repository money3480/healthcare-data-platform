{% test no_future_dates(model, column_name) %}
{# Fails if any value in column_name is a future date #}
SELECT {{ column_name }}
FROM {{ model }}
WHERE {{ column_name }} IS NOT NULL
  AND {{ column_name }} > CURRENT_DATE
{% endtest %}
