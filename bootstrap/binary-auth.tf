resource "google_binary_authorization_policy" "policy" {
  project = var.cicd_project_id
  admission_whitelist_patterns {
    name_pattern = "europe-west2-docker.pkg.dev/createlift-cicd/ar-mcm-createlift/*"
  }

  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.attestor.name]
  }
}

##### Binary Authorization Attestor Kms

resource "google_binary_authorization_attestor" "attestor" {
  project = var.cicd_project_id
  name    = "attestor"
  attestation_authority_note {
    note_reference = google_container_analysis_note.note.name
    public_keys {
      id = data.google_kms_crypto_key_version.version.id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.version.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.version.public_key[0].algorithm
      }
    }
  }
}

data "google_kms_crypto_key_version" "version" {
  crypto_key = google_kms_crypto_key.asymmetric-sign-key.id
}

resource "google_container_analysis_note" "note" {
  project = var.cicd_project_id
  name    = "attestor-note"
  attestation_authority {
    hint {
      human_readable_name = "Attestor Note"
    }
  }
}

resource "google_kms_crypto_key" "asymmetric-sign-key" {
  name     = "crypto-key-binauth"
  key_ring = google_kms_key_ring.keyring.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "EC_SIGN_P256_SHA256"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring" "keyring" {
  project  = var.cicd_project_id
  name     = "binauth-keyring"
  location = "global"
}
