#!/bin/bash
# Copyright (c) 2012-2017 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# Contributors:
# Red Hat, Inc. - initial implementation

set -e

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

if ! grep -Fq "${USER_ID}" /etc/passwd; then
    # current user is an arbitrary
    # user (its uid is not in the
    # container /etc/passwd). Let's fix that
    cat ${HOME}/passwd.template | \
    sed "s/\${USER_ID}/${USER_ID}/g" | \
    sed "s/\${GROUP_ID}/${GROUP_ID}/g" | \
    sed "s/\${HOME}/\/home\/user/g" > /etc/passwd

    cat ${HOME}/group.template | \
    sed "s/\${USER_ID}/${USER_ID}/g" | \
    sed "s/\${GROUP_ID}/${GROUP_ID}/g" | \
    sed "s/\${HOME}/\/home\/user/g" > /etc/group
fi

CHE_INFRASTRUCTURE_ACTIVE=openshift
CHE_OPENSHIFT_CERT_LOCATION=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
CHE_OPENSHIFT_SERVICE_CERT_LOCATION=/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
CHE_OPENSHIFT_SIGNER_CERT_LOCATION=/tmp/service-signer.crt
CHE_JAVA_CERT_LOCATION=/etc/ssl/certs/java/cacerts
if [ "${CHE_INFRASTRUCTURE_ACTIVE}" = "openshift" ]; then
    if [ -f ${CHE_OPENSHIFT_SERVICE_CERT_LOCATION} ] && [ -f ${CHE_OPENSHIFT_CERT_LOCATION} ] && [ -f ${CHE_JAVA_CERT_LOCATION} ]; then
        tail -$(($(grep -c "^" ${CHE_OPENSHIFT_SERVICE_CERT_LOCATION})-$(grep -c "^" ${CHE_OPENSHIFT_CERT_LOCATION})-1)) ${CHE_OPENSHIFT_SERVICE_CERT_LOCATION} > ${CHE_OPENSHIFT_SIGNER_CERT_LOCATION}
        keytool -importcert -noprompt -file ${CHE_OPENSHIFT_SIGNER_CERT_LOCATION} -storepass changeit -keystore ${CHE_JAVA_CERT_LOCATION} -alias openshiftcert
    fi
fi

if test "${USER_ID}" = 0; then
    # current user is root
    /usr/sbin/sshd -D &
elif sudo -n true > /dev/null 2>&1; then
    # current user is a suoder
    sudo /usr/sbin/sshd -D &
fi

exec "$@"
