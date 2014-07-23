# RbPath

RbPath is a small library for finding and retrieving data in large Ruby
collections (Arrays/Hashes) and object graphs, similar to XPath and CSS
selectors. You might use it over XPath or something similar because it's
super lightweight and may do exactly what you need without the complex
semantics of XPath or CSS selectors. It also makes operations such as regular
expression filtering much easier to use.


## Table of contents

 - [Installation](#installation)
 - [Usage](#usage)
 - [Queries](#queries)
  - [Literals](#literals)
  - [Wildcards](#wildcards)
  - [Logic Expressions](#logic-expressions)
  - [Regex Matching](#regex-matching)
  - [Gotchas](#gotchas)
 - [Working with JSON/YAML/XML](#working-with-jsonyamlxml)

## Installation

Add this line to your application's Gemfile:

    gem 'rbpath'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbpath

## Usage

### Direct

You can use the query engine directly through the Query class.

```ruby
require 'rbpath'

h = {...}

RbPath::Query.new(...).query(h)
```

### Object Mixin

You can add the query interface to an existing instance of a Hash or Array.

```ruby
require 'rbpath'

h = {...}
h.extend RbPath

h.query(...)
```

### Class Mixin

You can make your own objects queryable by using the RbPath mixin.

```ruby
require 'rbpath'

class Person < Struct.new(:first, :middle, :last, :age, :relatives)
  include RbPath

  rbpath :first, :middle, :last, :age, :relatives
end

p = Person.new('john', 'michael', 'doe', 21, [relative1,...])

p.query(...)
```

Notice that the rbpath attributes must be explicitly listed.

## Queries

Queries are similar to XPath expressions. They are used to navigate and find
information in tree-like data structures.

```ruby
class Employee < Struct.new(:first, :last, :position)
  include RbPath
  rbpath :first, :last, :position
end

data = {
  illinois: {
    chicago: {
      inventory: {
        bakery: { white: 220, whole_wheat: 150, multigrain: 72, rye: 27 },
        fish:   { salmon: 110, tuna: 115, flounder: 22, catfish: 90, cod: 15 },
        meat:   { ribeye: 23, pork_chop: 19, pork_loin: 12, beef_brisket: 30 }},
      employees: [
        Employee.new("John", "Sansk",   "General Manager"),
        Employee.new("Gene", "Pollack", "Warehouse Manager"),
        Employee.new("Luke", "Sanders", "Director")],
      address: '101 Big St',
      services: [:pharmacy, :bakery, :groceries, :kids_corner, :pet_grooming]
    },
    springfield: {
      inventory: {
        fish:   { salmon: 101, trout: 97, snapper: 172, catfish: 17, cod: 93 },
        meat:   { ribeye: 13, chuck_roast: 82, flank_steak: 73, beef_brisket: 30 }},
      employees: [
        Employee.new("Kerry",  "Adams",  "General Manager"),
        Employee.new("Sherry", "Nerst",  "Warehouse Manager"),
        Employee.new("Kate",   "Holmes", "Director")],
      address: '220 Small St',
      services: [:groceries, :kids_corner]
    }
  }
}

data.extend RbPath
```

The sample data above represents a chain of grocery stores and their employees.
We will see how RbPath can extract useful information from this set of data.


### Literals

The result of a *query* call will always be a list values that satisfy it, or
an empty list if no matching values were found. There is also an analagous
*pquery* interface which, instead of returning the values themselves, will
return the paths to the values (or an empty list). Calling *path_values* on the
result of *pquery* is the same as calling *query* directly.

To make the examples more concise, only results from the *pquery* call will be
provided in later examples.

```ruby
# Xpath: /illinois/chicago

> data.query("illinois chicago")
=> [{inventory: {...}, employees: [...], address: "...", services: [...]}]

> data.pquery("illinois chicago")
=> [['illinois','chicago']]

> data.path_values( data.pquery("illinois chicago") )
=> [{inventory: {...}, employees: [...], address: "...", services: [...]}]

# Xpath: /california/san_francisco

> data.query("california san_francisco")
=> []

> data.pquery("california san_francisco")
=> []
```

Notice that the elements are seperated by **spaces** instead of slashes, and rbpath
queries are **absolute** by default.

Because the access semantics for Ruby collections (Arrays vs Hashes vs Objects)
are inherently different, queries into Arrays will have numerical indices
while queries into Hashes and RbPath objects will usually have string
indices, much like in XPath.

``` ruby
# Xpath: /illinois/chicago/services[1]

> data.pquery("illinois chicago services 0")
=> [['illinois','chicago','services','0']]
```

Results to absolute queries aren't very interesting though, since they only
return a single match. Other queries can return multiple matching paths.

### Wildcards

The star in the query below represents a **wildcard** match. It allows us to
match more than one value at a particular depth in the tree.

```ruby
# XPath: /illinois/*/employees

> data.pquery("illinois * employees")
=> [['illinois','chicago','employees'],
      ['illinois','springfield','employees']]
```

Wildcards can also be span across multiple levels of the tree, in case you
don't know how deep your value lives. These **multi-level wildcards** will reach
across 0 or more depth levels.

```ruby
# XPath: //illinois

> data.pquery("** illinois")
=> [['illinois']]

# XPath: //employees

> data.pquery("** employees")
=> [['illinois','employees'],
      ['illinois','chicago','employees'],
      ['illinois','springfield','employees']]

```

Notice that paths of differnt lengths may be returned in the resulting set when
using multi-level wildcards.

### Logic Expressions

In addiction to wildcards, there is another, more restrictive, way to match
several paths at once using **AND** and **NOR** expressions.

```ruby
# XPath: /illinois/chicago/inventory/*/salmon | /illinois/chicago/inventory/*/pork_chop

> data.pquery("illinois chicago inventory * (salmon,pork_chop)")
=> [['illinois','chicago','inventory','fish','salmon'],
      ['illinois','chicago','inventory','meat','pork_chop']]
```

The above query will select all the inventory paths in the chicago store that
match 'salmon' **AND** 'pork_chop' for any of the departments. We can also
achieve the opposite effect by using a **NOR** expression and specifying  a
list of values to avoid matching.

```ruby
# XPath: /illinois/chicago/inventory/fish[not(contains(salmon)) and not(contains(tuna))]

> data.pquery("illinois chicago inventory fish [salmon,tuna]")
=> [['illinois','chicago','inventory','fish','flounder'],
      ['illinois','chicago','inventory','fish','catfish'],
      ['illinois','chicago','inventory','fish','cod']]
```

This query gives us all the fish in the chicago store which **do not match**
'salmon' or 'tuna'.

### Regex Matching

It's not always enough to be able to filter on an exact field/key name.
Sometimes you only know part of the name or you want to match all the names
that match a certain pattern. This is where regular expressions come in handy.

You can include plain old ruby regexes in your quries by splitting the query up
into multiple arguments. In this case the query will will still be processed as
though it was continuous.

```ruby
> data.pquery("illinois chicago inventory meat", /(pork.*|beef.*)/)
=> [['illinois','chicago','inventory','meat','pork_chop'],
      ['illinois','chicago','inventory','meat','pork_loin'],
      ['illinois','chicago','inventory','meat','beef_brisket']]

> data.pquery("illinois", /(chi.*|spr.*)/, "inventory *")
=> [['illinois','chicago','inventory','bakery'],
      ['illinois','chicago','inventory','fish'],
      ['illinois','chicago','inventory','meat'],
      ['illinois','springfield','inventory','fish'],
      ['illinois','springfield','inventory','meat']]
```

XPath 1.0 doesn't actually support regular expressions, but it does provide some
[specialized functions](http://www.w3.org/TR/xpath/#function-starts-with) for
partially matching element names such as *starts-with()* and *contains()*.

### Gotchas

Sometimes you may need to find strings with spaces or things which are not
strings at all. Here is how you do that.

Single quote your string or use a regex matcher when your filter string
contains spaces.

```ruby
> data.pquery("* * employees * position 'General Manager'")
=> [['illinois','chicago','employees','0','position','General Manager'],
      ['illinois','chicago','employees','0','position','General Manager']]

> data.pquery("* * employees 0 position", /General Manager/)
=> [['illinois','chicago','employees','0','position','General Manager'],
      ['illinois','chicago','employees','0','position','General Manager']]
```

Split up queries that use non-String filters into multiple arguments, just like
we did with regular expressions.

```ruby
> data.pquery("* * inventory * *", 30)
=> [['illinois','chicago','inventory','meat','beef_brisket',30],
      ['illinois','springfield','inventory','meat','beef_brisket',30]]
```

## Working With JSON/YAML/XML

You can use the **rq** command (which is installed with the gem) from your
shell to query JSON, YAML and XML files using the RbPath engine, but you
will not be able to match regular expressions or non-string values due to the
limitations of the query parser.

```bash
Usage: rq [OPTIONS] QUERY
    -f, --file  [FILE]       File to parse
    -t, --type  [TYPE]       File format
    -p, --paths              Paths only
    -h, --help               Show usage
```

- If you don't supply the *file* option then data will be read from STDIN.
- The *paths* option will mimic the *pquery* interface shown in the examples.

```bash
# read from a file
$ rq -f data.json '** john **'

# read from STDIN
$ curl http://myservice.com/api/1.json | rq -t json '** john **'
```

### XML

The [xml-simple](http://rubygems.org/gems/xml-simple) gem is used to convert
xml files to Ruby hashes prior to processing, so it must be installed if you
want to query XML files.

```bash
gem install xml-simple
```

### Pretty Printer

Installing the [hirb](http://rubygems.org/gems/hirb) gem will tabularize
certain types of output, making it much easier to read.

```bash
gem install hirb
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
