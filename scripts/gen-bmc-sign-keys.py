#!/usr/bin/env python3

import os
import sys
import shlex
import subprocess
from pathlib import Path

openbmc_meta_intel_path = Path(os.path.dirname(os.path.realpath(__file__))).parent
gen_bmc_signing_keys = openbmc_meta_intel_path / "scripts" / "keys" 

def write_file(data, fileName, mode):
    file = open(fileName, mode)
    file.write(data)
    file.close()

def run_command(command):
    print(command)
    rc = subprocess.check_call(command, shell=True)
    if rc:
        exit(1)


def gen_key_pairs(prv_file_path, pub_key_path):
    prv_key_gen_cmd = 'openssl ecparam -genkey -name secp384r1 -out ' + prv_file_path
    pub_key_gen_cmd = 'openssl ec -in ' + \
        prv_file_path + ' -pubout -out ' + pub_key_path
    run_command(prv_key_gen_cmd)
    run_command(pub_key_gen_cmd)
    return

def gen_cert(prv_key, cert_file):
    cert_csr = "rk_cert.csr"
    cert_param = "/CN=intel test ECP384 CA"
    cert_param = '"{}"'.format(cert_param)
    rk_csr_gen_cmd = 'openssl req -new -sha384 -key ' + \
        prv_key + ' -out ' + cert_csr + ' -subj ' + cert_param
    rk_cert_gen = 'openssl x509 -req -days 365 -in ' + cert_csr + \
        ' -signkey ' + prv_key + ' -sha384 -out ' + cert_file
    run_command(rk_csr_gen_cmd)
    run_command(rk_cert_gen)

def generate_bmc_signing_keys():
    pfr_rk_prv = "rk_prv.pem"
    pfr_rk_pub = "rk_pub.pem"
    pfr_rk_cert = "rk_cert.pem"
    pfr_csk_prv = "csk_prv.pem"
    pfr_csk_pub = "csk_pub.pem"

    saved_dir = os.getcwd()
    if not gen_bmc_signing_keys.exists():
        gen_bmc_signing_keys.mkdir(parents=True, exist_ok=True)
    os.chdir(gen_bmc_signing_keys)
    gen_key_pairs(pfr_rk_prv, pfr_rk_pub)
    gen_key_pairs(pfr_csk_prv, pfr_csk_pub)
    gen_cert(pfr_rk_prv, pfr_rk_cert)
    os.chdir(saved_dir)


def main():
    """
    generate_bmc_signing_keys
    """
    generate_bmc_signing_keys()

if __name__ == "__main__":
    main()
