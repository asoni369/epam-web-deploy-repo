import json
import jwt
import requests
from jwt.exceptions import InvalidTokenError
import os

COGNITO_USER_POOL_ID = os.getenv("COGNITO_USER_POOL_ID", "ap-southeast-2_nrNaFykzq")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")
AUDIENCE = os.getenv("COGNITO_CLIENT_ID", "3g5c4trra7rsqd7unh4ql8gq7l")
method_arn = os.getenv("METHOD_ARN", "arn:aws:execute-api:ap-southeast-2:445567099272:10a0zasgw8/*/*")

# URL to fetch public keys from Cognito
JWKS_URL = f"https://cognito-idp.{AWS_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}/.well-known/jwks.json"

def get_jwk():
    response = requests.get(JWKS_URL)
    jwks = response.json()
    print(f"Fetched JWKS: {jwks}")
    return {key["kid"]: key for key in jwks["keys"]}

def verify_token(token):
    headers = jwt.get_unverified_header(token)
    kid = headers["kid"]
    jwk = get_jwk().get(kid)

    if not jwk:
        raise Exception("Public key not found")

    public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(jwk))

    return jwt.decode(
        token,
        public_key,
        algorithms=["RS256"],
        audience=AUDIENCE,
        issuer=f"https://cognito-idp.{AWS_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}"
    )

def generate_policy(principal_id, effect, resource):
    return {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource
                }
            ]
        }
    }

def lambda_handler(event, context):
    print(f"Received event: {event}")

    token = event.get("authorizationToken", "")
    method_arn = event.get("methodArn")

    if not token.startswith("Bearer "):
        raise Exception("Unauthorized")

    try:
        jwt_token = token.split(" ")[1]
        decoded = verify_token(jwt_token)
        principal_id = decoded["sub"]
        return generate_policy(principal_id, "Allow", method_arn)

    except InvalidTokenError as e:
        print(f"Token verification failed: {e}")
        raise Exception("Unauthorized")
