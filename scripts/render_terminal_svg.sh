#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "uso: $0 <entrada.txt> <saida.svg>" >&2
  exit 1
fi

input_file=$1
output_file=$2

if [ ! -f "$input_file" ]; then
  echo "arquivo nao encontrado: $input_file" >&2
  exit 1
fi

tmp_body=$(mktemp)
trap 'rm -f "$tmp_body"' EXIT

max_width=0
line_count=0

while IFS= read -r line || [ -n "$line" ]; do
  escaped=$(printf '%s' "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
  printf '  <text x="24" y="%s">%s</text>\n' "$((54 + line_count * 22))" "$escaped" >> "$tmp_body"
  line_length=${#line}
  if [ "$line_length" -gt "$max_width" ]; then
    max_width=$line_length
  fi
  line_count=$((line_count + 1))
done < "$input_file"

if [ "$line_count" -eq 0 ]; then
  line_count=1
fi

svg_width=$((max_width * 9 + 60))
svg_height=$((line_count * 22 + 80))

cat > "$output_file" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$svg_width" height="$svg_height" viewBox="0 0 $svg_width $svg_height" role="img" aria-label="Saida de terminal">
  <rect width="100%" height="100%" rx="18" fill="#0f172a"/>
  <rect x="12" y="12" width="$((svg_width - 24))" height="$((svg_height - 24))" rx="14" fill="#111827" stroke="#334155"/>
  <circle cx="36" cy="34" r="6" fill="#f87171"/>
  <circle cx="56" cy="34" r="6" fill="#fbbf24"/>
  <circle cx="76" cy="34" r="6" fill="#34d399"/>
  <text x="104" y="39" fill="#94a3b8" font-family="monospace" font-size="16">terminal</text>
  <g fill="#e5e7eb" font-family="monospace" font-size="16">
$(cat "$tmp_body")
  </g>
</svg>
EOF
