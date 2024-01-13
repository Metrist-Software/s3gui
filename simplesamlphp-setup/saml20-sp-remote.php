<?php
/**
 * Override file for saml20-sp-remote.php to force an HTTP-POST single logout (the only thing Samly supports)
 * 
 * SAML 2.0 remote SP metadata for SimpleSAMLphp.
 *
 * See: https://simplesamlphp.org/docs/stable/simplesamlphp-reference-sp-remote
 */

if (!getenv('SIMPLESAMLPHP_SP_ENTITY_ID')) {
    throw new UnexpectedValueException('SIMPLESAMLPHP_SP_ENTITY_ID is not defined as an environment variable.');
}
if (!getenv('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE')) {
    throw new UnexpectedValueException('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE is not defined as an environment variable.');
}

$metadata[getenv('SIMPLESAMLPHP_SP_ENTITY_ID')] = array(
    'AssertionConsumerService' => getenv('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE'),
    'SingleLogoutService' => 
    array(
            0 =>
            array(
                    'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
                    'Location' => getenv('SIMPLESAMLPHP_SP_SINGLE_LOGOUT_SERVICE'),
                ),
    )
);


if (!getenv('SIMPLESAMLPHP_SP_ENTITY_ID2')) {
    throw new UnexpectedValueException('SIMPLESAMLPHP_SP_ENTITY_ID2 is not defined as an environment variable.');
}
if (!getenv('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE2')) {
    throw new UnexpectedValueException('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE2 is not defined as an environment variable.');
}

$metadata[getenv('SIMPLESAMLPHP_SP_ENTITY_ID2')] = array(
    'AssertionConsumerService' => getenv('SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE2'),
    'SingleLogoutService' => 
    array(
            0 =>
            array(
                    'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
                    'Location' => getenv('SIMPLESAMLPHP_SP_SINGLE_LOGOUT_SERVICE2'),
                ),
    )
);