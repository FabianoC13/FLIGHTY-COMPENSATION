"""Run: python3 -m unittest discover -s server/tests"""
import hashlib
import hmac
import importlib
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


def load(env):
    for key in ("DLOCAL_WEBHOOK_SECRET", "DLOCAL_SECRET_KEY", "PAYOUT_API_TOKEN", "PAYOUT_DEV_MODE"):
        os.environ.pop(key, None)
    os.environ.update(env)
    import payout_server
    return importlib.reload(payout_server)


class WebhookSignatureTests(unittest.TestCase):
    def sign(self, secret, login, date, body):
        return "V2-HMAC-SHA256, Signature: " + hmac.new(secret.encode(), login.encode() + date.encode() + body, hashlib.sha256).hexdigest()

    def test_valid_signature_accepted(self):
        ps = load({"DLOCAL_WEBHOOK_SECRET": "s3cret"})
        body = b'{"type":"payout.paid"}'
        auth = self.sign("s3cret", "login", "2026-10-12T00:00:00Z", body)
        self.assertTrue(ps.verify_dlocal_signature(body, "login", "2026-10-12T00:00:00Z", auth))

    def test_tampered_body_rejected(self):
        ps = load({"DLOCAL_WEBHOOK_SECRET": "s3cret"})
        auth = self.sign("s3cret", "login", "d", b'{"type":"payout.failed"}')
        self.assertFalse(ps.verify_dlocal_signature(b'{"type":"payout.paid"}', "login", "d", auth))

    def test_missing_signature_rejected(self):
        ps = load({"DLOCAL_WEBHOOK_SECRET": "s3cret"})
        self.assertFalse(ps.verify_dlocal_signature(b"{}", "login", "d", ""))

    def test_no_secret_rejects_unless_dev_mode(self):
        self.assertFalse(load({}).verify_dlocal_signature(b"{}", "", "", ""))
        self.assertTrue(load({"PAYOUT_DEV_MODE": "1"}).verify_dlocal_signature(b"{}", "", "", ""))


class ApiTokenTests(unittest.TestCase):
    def test_bearer_token(self):
        ps = load({"PAYOUT_API_TOKEN": "tok"})
        self.assertTrue(ps.is_authorized_bearer("Bearer tok"))
        self.assertFalse(ps.is_authorized_bearer("Bearer nope"))
        self.assertFalse(ps.is_authorized_bearer(None))

    def test_no_token_configured_rejects(self):
        self.assertFalse(load({}).is_authorized_bearer("Bearer anything"))


if __name__ == "__main__":
    unittest.main()
