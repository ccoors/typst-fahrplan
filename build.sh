#!/usr/bin/env sh

set -eux

version=$(git rev-parse --short HEAD)
output_format="${1:-pdf}"

mkdir -p dist
for fp in data/*.yaml data.yaml; do
    bn=$(basename -s .yaml $fp)
    typst compile -f ${output_format} fahrplan.typ --input "datafile=${fp}" --input version=${version} "dist/fahrplan_${bn}.${output_format}" &
    typst compile -f ${output_format} fahrplan.typ --input "datafile=${fp}" --input yellow=true --input version=${version} "dist/yellow_fahrplan_${bn}.${output_format}" &
done
wait
