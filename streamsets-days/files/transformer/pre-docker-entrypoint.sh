#!/bin/bash
# Pre-runner for Transformer

echo
echo "$(date -Iseconds) Entering: $0"
echo
set -e

# Install sample pipelines
if [ -z "${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}" ]
then
  echo "INFO: No sample pipelines to install.  SDC_INSTALL_SAMPLE_PIPELINES not configured."
elif [ ! -d "${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}" ]
then
  echo "ERROR: TRANSFORMER_INSTALL_SAMPLE_PIPELINES did not specify a folder.  TRANSFORMER_INSTALL_SAMPLE_PIPELINES=${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}"
else
  echo "Installing sample pipelines ${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}/*"
  # Recurse.  And do not copy if the file is older.
  if [ ! -r "${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}"/* ]
  then
    echo "WARNING: ${TRANSFORMER_INSTALL_SAMPLE_PIPELINES} cannot be read."
  else
    cp -r -u "${TRANSFORMER_INSTALL_SAMPLE_PIPELINES}"/* "${TRANSFORMER_DIST}/samplePipelines/"
  fi
fi


escape_pipes() {
  echo "${1//|/\\|}"
}

# We translate environment variables to sdc.properties and rewrite them.
set_conf() {
  local escaped
  if [ $# -lt 2 ]; then
    echo "set_conf requires at least two arguments: <key> <value> [<filename>]"
    exit 1
  fi
  if [ -z "$TRANSFORMER_CONF" ]; then
    echo "TRANSFORMER_CONF is not set."
    exit 1
  fi
  if [ -z "$3" ]; then
    for f in ${TRANSFORMER_CONF}/*.properties; do
      set_conf "$1" "$2" "$f"
    done
  else
    escaped=$(escape_pipes "$2")
    set -x
    sed -i 's|^#\?\('"$1"'=\).*|\1'"${escaped}"'|I' "$3"
    set +x
  fi
}
#set_conf() {
#  if [ $# -ne 2 ]; then
#    echo "set_conf requires two arguments: <key> <value>"
#    exit 1
#  fi
#
#  if [ -z "$TRANSFORMER_CONF" ]; then
#    echo "TRANSFORMER_CONF is not set."
#    exit 1
#  fi
#
#  grep -q "^$1" ${TRANSFORMER_CONF}/transformer.properties && sed 's|^#\?\('"$1"'=\).*|\1'"$2"'|' -i ${TRANSFORMER_CONF}/transformer.properties || echo -e "\n$1=$2" >> ${TRANSFORMER_CONF}/transformer.properties
#}

#env -0 | while IFS='=' read -r -d '' key value; do
for e in $(env); do
  key=${e%=*}
  value=${e#*=}
  # First check for hard wired mapping of DPM_CONF_LDAP variables
  # Then check for DPM_CONF_LDAP_L_* special config.
  # Finally check for all other DPM_CONF_* variables
  case "$key" in
  DPM_CONF_LDAP_HOSTNAME)
    # Select the "L" set of configurations
    set_conf "userGroupProvider.M.multi.ids" "L" "${DPM_CONF}/security-app.properties"
    # And specify the host name.
    set_conf "userGroupProvider.M.multi.L.ldap.hostname" "${DPM_CONF_LDAP_HOSTNAME}" "${DPM_CONF}/security-app.properties"
  ;;
  DPM_CONF_LDAP_PORT)
    set_conf "userGroupProvider.M.multi.L.ldap.port" "${DPM_CONF_LDAP_PORT}" "${DPM_CONF}/security-app.properties"
  ;;
  DPM_CONF_LDAP_LDAPS)
    set_conf "userGroupProvider.M.multi.L.ldap.ldaps" "${DPM_CONF_LDAP_LDAPS}" "${DPM_CONF}/security-app.properties"
  ;;
  DPM_CONF_LDAP_L_*)
    # Configuration is mapped to userGroupProvider.M.multi.L.
    # Remove the prefix and replace underscores with periods
    key=$(echo "${key#*DPM_CONF_LDAP_L_}" | sed 's|_|.|g')
    # If the key is mixed case then use exactly what they specified
    # Otherwise, convert to lower case.
    if [[ $key == $(echo "${key}" | tr '[:lower:]' '[:upper:]') ]]; then
      # Convert to lower case
      key=$(echo "${key}" | tr '[:upper:]' '[:lower:]')
    fi
#    echo "userGroupProvider.M.multi.L.${key} ${value} ${DPM_CONF}/security-app.properties"
    set_conf "userGroupProvider.M.multi.L.${key}" "${value}"  "${DPM_CONF}/security-app.properties"
  ;;
  TRANSFORMER_CONF_*)
    # Remove the prefix, replace underscores with periods and convert to lower case
    key=$(echo "${key#*TRANSFORMER_CONF_}" | sed 's|_|.|g' | tr '[:upper:]' '[:lower:]')
    set_conf "${key}" "${value}"
  ;;
  esac
done

echo "$(date -Iseconds) Exiting: $0"
exec /docker-entrypoint.sh "$@"
