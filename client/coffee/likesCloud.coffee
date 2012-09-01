d3.json("/person/mapReduce/likesHistogram/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'

  fontSize = d3.scale.log().range([10, 100])
  d3.layout.cloud().size([1000, 1000])
    .words(json.filter((d) -> d.likes > 5).map((d) -> {text: d.name, value: d.likes}))
    .rotate(() -> ~~(Math.random() * 8) * 90)
    .fontSize((d) -> (+d.value))
    .on("end", (words) ->
      d3.select("#chart").append("svg")
        .attr("width", 1000)
        .attr("height", 1000)
        .append("g")
        .attr("transform", "translate(150,150)")
        .selectAll("text")
        .data(words)
        .enter().append("text")
        .style("font-size", (d) -> d.size + "px")
        .attr("text-anchor", "middle")
        .attr("transform", (d) -> "translate(#{ [d.x, d.y]})rotate(#{d.rotate})")
        .text((d) -> d.text))
        .start()
)
