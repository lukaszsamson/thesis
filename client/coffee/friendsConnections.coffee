width = 960
height = 600

color = d3.scale.category20()

force = d3.layout.force()
  .charge(-120)
  .linkDistance(180)
  .size([width, height])

svg = d3.select("#chart")
  .append("svg")
  .attr("width", width)
  .attr("height", height)

d3.json("/person/mapReduce/friendsConnections/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'

  nodes = json.people
  connections = []
  for c in json.connections
    from = to = -1
    for i in [0...nodes.length]
      if nodes[i].id == c.from
        from = i
        break
    for i in [0...nodes.length]
      if nodes[i].id == c.to
        to = i
        break
    connections.push {
      source: from
      target: to
      value: 1
    }


  force
    .nodes(nodes)
    .links(connections)
    .start();

  link = svg.selectAll("line.link")
    .data(connections)
    .enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> Math.sqrt(d.value))

  node = svg.selectAll("circle.node")
    .data(nodes)
    .enter().append("circle")
    .attr("class", "node")
    .attr("r", 5)
    .style("fill", (d) -> color(if d.user then 0 else 1))
    .call(force.drag);

  node.append("title")
    .text((d) -> d.name)

  force.on("tick", () ->
    link.attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    node.attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
  )
)


