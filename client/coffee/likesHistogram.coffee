

# A formatter for counts.
#formatCount = d3.format(",.0f")
formatCount = (d) -> d.toString()
margin = {top: 10, right: 30, bottom: 30, left: 30}
width = 600 - margin.left - margin.right
height = 400 - margin.top - margin.bottom

d3.json("/person/mapReduce/likesHistogram/results", (json) ->
  if not json
    return window.showModal 'No data found', 'You have to request analysis first.'

  values = json.map (d) -> d.likes

  x = d3.scale.linear()
    .domain([0.5, 15.5])
    .range([0, width])


  # Generate a histogram using twenty uniformly-spaced bins.
  data = d3.layout.histogram().bins(15)(values)

  y = d3.scale.log()
    .domain([0.1, d3.max(data, (d) -> d.y )])
    .nice()
    .range([height, 0])

  xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")

  svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

  bar = svg.selectAll(".bar")
    .data(data)
    .enter().append("g")
    .attr("class", "bar")
    .attr("transform", (d) -> "translate(#{x(0.5 + (d.x-1) / data[0].dx)}, #{y(d.y)})")

  bar.append("rect")
    .attr("x", 1)
    .attr("width", x(1.5) - 1)
    .attr("height", (d) ->
        if isNaN(y(d.y)) or not isFinite(y(d.y)) then 0 else height - y(d.y)
    )

  bar.append("text")
    .attr("dy", ".75em")
    .attr("y", 6)
    .attr("x", x(1.5) / 2)
    .attr("text-anchor", "middle")
    .text((d) -> formatCount(d.y))

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0, #{height})")
    .call(xAxis)

)