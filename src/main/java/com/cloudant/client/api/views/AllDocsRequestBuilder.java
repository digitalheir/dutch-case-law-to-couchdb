/*
 * Copyright (c) 2015 IBM Corp. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied. See the License for the specific language governing permissions
 * and limitations under the License.
 */

package com.cloudant.client.api.views;

/**
 * Interface for building an unpaginated _all_docs request.
 * <P>
 * Example usage:
 * </P>
 * <pre>
 * {@code
 *
 * AllDocsRequest allDocsRequest =
 * //get a request builder for the "_all_docs" endpoint
 * db.getAllDocsRequestBuilder()
 *
 *   //set any other required parameters e.g. doc id of "foo" or "bar"
 *   .keys("foo", "bar")
 *
 *   //build the request
 *   .build();
 * }
 * </pre>
 */
public interface AllDocsRequestBuilder extends RequestBuilder<AllDocsRequestBuilder>,
        SettableViewParameters.Unpaginated<String, AllDocsRequestBuilder> {

    /**
     * @return the built AllDocsRequest
     * @since 2.0.0
     */
    AllDocsRequest build();
}
