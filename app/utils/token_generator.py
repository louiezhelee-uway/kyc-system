import secrets
import string

def generate_verification_token(length: int = 32) -> str:
    """
    Generate a secure random verification token
    """
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def generate_api_key(length: int = 32) -> str:
    """
    Generate a secure random API key
    """
    alphabet = string.ascii_letters + string.digits + string.punctuation
    return ''.join(secrets.choice(alphabet) for _ in range(length))
