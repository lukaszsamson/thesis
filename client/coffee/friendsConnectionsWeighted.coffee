partition = (vertices, connections) ->
  sources = {}
  nodes = []
  for v in vertices
    if not sources[v[0]]
      sources[v[0]] = [v[1]]
    else
      sources[v[0]].push(v[1])
    if nodes.indexOf(v[0]) == -1
      nodes.push(v[0])
    if nodes.indexOf(v[1]) == -1
      nodes.push(v[1])
      
  partitions = []
  for source, targets of sources
    p = {
      id: Math.max.apply(null, targets.concat(source))
      source: parseInt(source, 10)
      targets: targets
    }
    partitions.push(p)
    console.log('%d %d %s', p.id, p.source, p.targets)

  console.log(partitions)
    
  iter = 1
  change = true
  while change
    console.log('after iteration %d', iter)
    iter++
    change = false
    maxIds = {}
      
    for n in nodes
      max = -1
      for p in partitions
        if p.id > max
          if p.source == n or p.targets.indexOf(n) != -1
            max = p.id
      maxIds[n] = max
    
    for p in partitions
      newId = Math.max.apply(null, p.targets.map((t) -> maxIds[t]).concat(maxIds[p.source]))
      if newId != p.id
        console.log('id %d changed to %d', p.id, newId)
        p.id = newId
        change = true
        
      console.log('%d %d %s', p.id, p.source, p.targets)
      
  for c in connections
    found = false
    for p in partitions
      if p.source == c.source and p.targets.indexOf(c.target) != -1
        found = true
        c.partition = p.id
        break
    if not found
      alert(c)

width = 960
height = 600

color = d3.scale.category20()

force = d3.layout.force()
  .charge(-120)
  .linkDistance(120)
  .size([width, height])

svg = d3.select("#chart")
  .append("svg")
  .attr("width", width)
  .attr("height", height)

d3.json("/person/mapReduce/friendsConnectionsWeighted/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'

  nodes = json.people
  connections = []
  for c in json.connections
    from = to = -1
    value = c.value
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
      value: value
    }
  connections = connections.filter((l) -> l.value > 1 and l.source != 0 and l.target != 0)
  vertices = connections.map((l) -> [l.source, l.target])  
    
  partition vertices, connections

  force
    .nodes(nodes)
    .links(connections)
    .linkDistance((d) -> 180 / Math.sqrt(d.value))
    .start();

  link = svg.selectAll("line.link")
    .data(connections)
    .enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> Math.sqrt(d.value))
    .style("stroke", (d) -> color(d.partition % 20))

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


