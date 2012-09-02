width = 620
height = 620
outerRadius = Math.min(width, height) / 2 - 10
innerRadius = outerRadius - 24

formatPercent = d3.format("1")
color = d3.scale.category20()
arc = d3.svg.arc()
  .innerRadius(innerRadius)
  .outerRadius(outerRadius)

layout = d3.layout.chord()
  .padding(0.04)
  .sortSubgroups(d3.descending)
  .sortChords(d3.ascending)

path = d3.svg.chord()
  .radius(innerRadius)

svg = d3.select("#chart").append("svg")
  .attr("width", width)
  .attr("height", height)
  .append("g")
  .attr("id", "circle")
  .attr("transform", "translate(#{width / 2}, #{height / 2})")

svg.append("circle")
  .attr("r", outerRadius)


d3.json("/person/mapReduce/linksFlow/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'

  for i in [0...json.axis.length]
    json.axis[i].color = color(i)
  # Compute the chord layout.
  layout.matrix(json.matrix)

  fade = (opacity) ->
    return (g, i) ->
      chord
        .filter((d) -> d.source.index != i && d.target.index != i)
        .transition()
        .style("opacity", opacity)

  # Add a group per neighborhood.
  group = svg.selectAll(".group")
    .data(layout.groups)
    .enter().append("g")
    .attr("class", "group")
    .on("mouseover", fade(0.1))
    .on("mouseout", fade(1))

  # Add a mouseover title.
  group.append("title").text((d, i) ->
    json.axis[i].name + ": " + formatPercent(Math.round(d.value)) + " of origins"
  )

  # Add the group arc.
  groupPath = group.append("path")
    .attr("id", (d, i) -> "group" + i)
    .attr("d", arc)
    .style("fill", (d, i) -> json.axis[i].color)

  # Add a text label.
  groupText = group.append("text")
    .attr("x", 6)
    .attr("dy", 15)

  groupText.append("textPath")
    .attr("xlink:href", (d, i) -> "#group" + i)
    .text((d, i) -> json.axis[i].name)

  # Remove the labels that don't fit. :(
  groupText.filter((d, i) -> groupPath[0][i].getTotalLength() / 2 - 16 < this.getComputedTextLength())
    .remove()

  # Add the chords.
  chord = svg.selectAll(".chord")
    .data(layout.chords)
    .enter().append("path")
    .attr("class", "chord")
    .style("fill", (d) -> json.axis[d.source.index].color)
    .attr("d", path)

  # Add an elaborate mouseover title for each chod.
  chord.append("title").text((d) ->
    json.axis[d.source.index].name + " → " + json.axis[d.target.index].name + ": " + formatPercent(d.source.value) + "\n" + json.axis[d.target.index].name + " → " + json.axis[d.source.index].name + ": " + formatPercent(d.target.value)
  )



)

