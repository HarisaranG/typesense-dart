import 'dart:collection';

import 'configuration.dart';
import 'multi_search.dart';
import 'collection.dart';
import 'services/node_pool.dart';
import 'services/request_cache.dart';
import 'services/api_call.dart';
import 'services/documents_api_call.dart';

class SearchClient {
  final Configuration config;
  final ApiCall _apiCall;
  final DocumentsApiCall _documentsApiCall;
  final MultiSearch multiSearch;
  final _individualCollections = HashMap<String, Collection>();

  SearchClient._(
    this.config,
    this._apiCall,
    this._documentsApiCall,
    this.multiSearch,
  );

  factory SearchClient(Configuration config) {
    // In v0.20.0 query params are restricted to 2000 in length. But sometimes
    // scoped API keys can be over this limit, so long keys are sent as headers
    // instead. The tradeoff is that using a header to send the API key will
    // trigger the browser to send an OPTIONS request first.
    config = config.copyWith(
      sendApiKeyAsQueryParam: (config.apiKey.length < 2000),
    );

    final nodePool = NodePool(config),
        apiCall = ApiCall(config, nodePool, RequestCache());
    return SearchClient._(
      config,
      apiCall,
      DocumentsApiCall(config, nodePool),
      MultiSearch(apiCall, useTextContentType: true),
    );
  }

  /// Perform operation on an individual collection having [collectionName].
  Collection collection(String collectionName) {
    if (!_individualCollections.containsKey(collectionName)) {
      _individualCollections[collectionName] =
          Collection(collectionName, _apiCall, _documentsApiCall);
    }
    return _individualCollections[collectionName];
  }
}
