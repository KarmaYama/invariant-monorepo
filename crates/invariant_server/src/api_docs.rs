/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use utoipa::OpenApi;
use invariant_shared::{GenesisRequest, Heartbeat, Identity, IdentityStatus, Network};

#[derive(OpenApi)]
#[openapi(
    paths(
        // We use full paths to ensure the macro finds the generated __path_ structs
        crate::handlers::genesis::genesis_handler,
        crate::handlers::genesis::verify_stateless_handler,
        crate::handlers::genesis::get_challenge_handler,
        crate::handlers::heartbeat::heartbeat_handler,
        crate::handlers::heartbeat::get_heartbeat_challenge_handler,
    ),
    components(
        schemas(GenesisRequest, Heartbeat, Identity, IdentityStatus, Network)
    ),
    tags(
        (name = "invariant", description = "Invariant Protocol API")
    ),
    info(
        title = "Invariant Node API",
        version = "1.0.0",
        description = "Hardware-entangled identity verification node."
    )
)]
pub struct ApiDoc;