// Rewrite client-side routes to root index.html (Vite/React/Vue SPA on S3 REST origin).
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.includes('.')) {
    return request;
  }

  request.uri = '/index.html';
  return request;
}
