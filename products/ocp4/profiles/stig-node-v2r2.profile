---
documentation_complete: true

platform: ocp4-node

metadata:
    version: V2R2
    SMEs:
        - Vincent056
        - rhmdnd
        - yuumasato

reference: https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RH_OpenShift_Container_Platform_4-12_V2R2_STIG.zip

title: 'DISA STIG for Red Hat OpenShift Container Platform 4 - Node level'

description: |-
    This profile contains configuration checks that align to the DISA STIG for
    Red Hat OpenShift Container Platform 4.

filter_rules: '"ocp4-node" in platform or "ocp4-master-node" in platform or "ocp4-node-on-sdn" in platform
    or "ocp4-node-on-ovn" in platform'

selections:
    - stig_ocp4:all
