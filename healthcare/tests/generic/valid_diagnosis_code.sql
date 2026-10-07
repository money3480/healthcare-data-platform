{% test valid_diagnosis_code(model, column_name) %}
{#
  Validates ICD-10-CM diagnosis code format:
  - Starts with a letter (A-Z)
  - Followed by 2 digits
  - Optionally followed by a decimal point and 1–4 more characters
  Examples: I10, E11.9, Z00.00, M54.5
#}
SELECT {{ column_name }}
FROM {{ model }}
WHERE {{ column_name }} IS NOT NULL
  AND NOT REGEXP_LIKE({{ column_name }}, '^[A-Z][0-9]{2}(\\.[0-9A-Z]{1,4})?$')
{% endtest %}
