w = 960
h = 600
fill = d3.scale.category20b()
draw = (data, bounds) ->
  #statusText.style("display", "none");
  scale = bounds ? Math.min(
    w / Math.abs(bounds[1].x - w / 2),
  w / Math.abs(bounds[0].x - w / 2),
  h / Math.abs(bounds[1].y - h / 2),
  h / Math.abs(bounds[0].y - h / 2)) / 2 : 1;
  words = data;
  text = vis.selectAll("text")
    .data(words, (d) -> d.text.toLowerCase())
  text.transition()
    .duration(1000)
    .attr("transform", (d) -> "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")")
    .style("font-size", (d) -> d.size + "px")
  text.enter().append("text")
    .attr("text-anchor", "middle")
    .attr("transform", (d) -> "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")")
    .style("font-size", (d) -> d.size + "px")
    .on("click", (d) ->
      load(d.text)
    )
    .style("opacity", 1e-6)
    .transition()
    .duration(1000)
    .style("opacity", 1);
  text.style("font-family", (d) -> d.font)
    .style("fill", (d) -> fill(d.text.toLowerCase()))
    .text((d) -> d.text)
  exitGroup = background.append("g")
    .attr("transform", vis.attr("transform"))
  exitGroupNode = exitGroup.node()
  text.exit().each(() -> exitGroupNode.appendChild(@))
  exitGroup.transition()
    .duration(1000)
    .style("opacity", 1e-6)
    .remove()
  d3.select(".progress .bar")
    .style("width", "100%")
#  vis.transition()
#    .delay(1000)
#    .duration(750)
#    .attr("transform", "translate(" + [w >> 1, h >> 1] + ")scale(" + scale + ")")

svg = d3.select("#chart").append("svg")
  .attr("width", w)
  .attr("height", h);

background = svg.append("g")
vis = svg.append("g")
  .attr("transform", "translate(" + [w >> 1, h >> 1] + ")")

d3.json("/person/mapReduce/likesHistogram/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'
  words = json.filter((d) -> d.likes > 2).reverse().map((d) -> {text: d.name, value: d.likes})
  cnt = 0
  len = words.length
  fontSize = d3.scale.log().range([1, 50])
  d3.select(".progress .bar")
    .style("width", "0%")
  d3.layout.cloud()
    .size([w, h])
    .timeInterval(10)
    .text((d) -> d.text)
    .font("Impact")
    .fontSize((d) -> fontSize(+d.value))
    .rotate((d) -> ~~(Math.random() * 5) * 30 - 60)
    .padding(1)
    .on("word", (word) ->
      d3.select(".progress .bar")
        .style("width", "#{++cnt * 100 / len}%")
    )
    .on("end", draw)
    .words(words)
    .start()
)
#.size([960, 600])
#    .timeInterval(10)
#    .font("Impact")
#    #.words(json.filter((d) -> d.likes > 5).map((d) -> {text: d.name, value: d.likes}))
#    .words([{text: 'sdcvdf', value: 3}, {text: 'sfbvbe', value: 5}, {text: 'pjbmt', value: 2}, {text: 'qdcxzc', value: 1},
#      {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3},
#      {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3},
#      {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, {text: 'sdcvdf', value: 3}, ])
#    .rotate(() -> ~~(Math.random() * 5) * 30 - 60)
#    .fontSize((d) -> (+d.value))
#    .on("end", (words) ->
#      d3.select("#chart").append("svg")
#        .attr("width", 2000)
#        .attr("height", 2000)
#        .append("g")
#        .attr("transform", "translate(150,150)")
#        .selectAll("text")
#        .data(words)
#        .enter().append("text")
#        .style("font-size", (d) -> fontSize(d.size) + "px")
#        .attr("text-anchor", "middle")
#        .attr("transform", (d) -> "translate(#{ [d.x, d.y]})rotate(#{d.rotate})")
#        .text((d) -> d.text))
#        .start()
#)


