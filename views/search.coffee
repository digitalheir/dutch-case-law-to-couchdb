###*
Get search return function: if there's a bookmark, this is a continued search and the results should be appended, not replaced.
@param isContinuedSearch whether this is a continued search; the bookmark that proves it
@returns {Function} function to use when we get the results
###
getFunctionForBookmark = (isContinuedSearch) ->
  (data) ->
    items = []
    $sres = $("#search-results")
    if data

      #Replace old with new results
      if searchState.bookmark is data["bookmark"]

        #We did not progress
        searchState.bookmark = null
      else
        searchState.bookmark = data["bookmark"]
      rows = data["rows"]
      i = 0

      while i < rows.length
        doc = rows[i]

        title = doc["fields"]["title"]
        subtitle = doc["fields"]["ecli"]
        ecliRegex = new RegExp("^\\s*#{subtitle}\\s*");
        title=title.replace(ecliRegex, '')

        htmlSnippet = "<!--suppress HtmlUnknownTarget -->
<div class='result nl case-law'>
 <a href='/ecli/#{doc["id"]}' id='#{doc["id"]}'>
  <div class='res-title'>#{title}</div>
  <div class='res-kind'>#{subtitle}</div>
 </a>"
        htmlSnippet += "</div>"
        if isContinuedSearch
          $sres.append htmlSnippet
        else
          items.push htmlSnippet
        i++
    else
      console.error "No data!"
      searchState.bookmark = null
    $sres.html items.join("")  unless isContinuedSearch
    $noResults = $("#no-results")
    if isContinuedSearch or items.length > 0
      $noResults.removeClass "show"
    else
      $noResults.addClass "show"
      searchState.bookmark = null
    return
inputMaybeChanged = ->
  q = $("input#search").val().trim()
  newSearch q  unless searchState.lastQuery is q
  return
getUrlForQuery = (q, bookmark) ->
  formQuery = q.trim()
  # The following characters require escaping if you want to search on them;
  # + - && || ! ( ) { } [ ] ^ " ~ * ? : \ /
  # Test:
  # "+ - && || ! ( ) { } [ ] ^ \" ~ * ? : \ /".replace(/\+|-|&|\||!|\(|\)|\{|\}|\[|\]|\^|"|~|\*|\?|:|\\|\//g,'');
  formQuery = formQuery.replace(/\+|-|&|\||!|\(|\)|\{|\}|\[|\]|\^|"|~|\*|\?|:|\\|\//g, "")
  formQuery = formQuery.replace(/(\s+|^)([0-9]+)(\s+|$)/g, '$1"$2"$3')

  query = null
  if formQuery.length > 0
    if formQuery[formQuery.length - 1] == '"'
      query = "default:" + formQuery
    else
      query = "default:" + formQuery + "* OR default:" + formQuery
  else
    query = "*:*"
  postfix = "limit=25&callback=?"
  postfix += "&bookmark=" + searchState.bookmark  if searchState.bookmark

  postfix += "&q=" + encodeURIComponent(query)
  BASE_URL + postfix

newSearch = (inpQuery, bkmrk) ->
  searchState.currentXhr.abort()  if searchState.currentXhr
  searchState.lastQuery = inpQuery

  #Format query for Lucene search
  url = getUrlForQuery(inpQuery, bkmrk)

  #TODO on error, show an error
  searchState.currentXhr = $.ajax(
    cache: true
    dataType: "jsonp"
    method: "GET"
    url: url
    success: getFunctionForBookmark(bkmrk)
  ).always(->
    searchState.currentXhr = null
    return
  )
  return

class SearchState
  constructor: () ->
    @currentXhr = null
    @lastQuery = null
    @bookmark = null

BASE_URL = "http://rechtspraak.cloudant.com/rechtspraak/_design/rechtspraak/_search/nonEmptyDocs?"
searchState = new SearchState()
$("input#search").on
  keyup: inputMaybeChanged
  change: inputMaybeChanged
#Continue searching
$(window).scroll ->
  return  if searchState.currentXhr
  if searchState.bookmark
    if $(window).scrollTop() + 72 >= ($(document).height() - $(window).height())
      newSearch searchState.lastQuery, searchState.bookmark
  return

# Start searching if there's a value in the input
startingQuery = $("#search").val()
newSearch startingQuery, null  if startingQuery