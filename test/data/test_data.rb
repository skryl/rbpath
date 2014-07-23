require_relative '../test_helper'

module TestData
  class Employee < Struct.new(:first, :last, :position)
    include RbPath
    rbpath :first, :last, :position
  end

  STORE_DATA =
    {
      illinois: {
        employees: [
          Employee.new("Kerry",  "Adams",  "District Manager")],
        chicago: {
          inventory: {
            apples: { granny_smith: 150, gala: 200, cameo: 150, honeycrisp: 75 },
            bread:  { white: 220, whole_wheat: 150, multigrain: 72, rye: 27 },
            fish:   { salmon: 110, tuna: 115, flounder: 22, catfish: 90, cod: 15 },
            meat:   { ribeye: 23, pork_chop: 19, pork_loin: 12, beef_brisket: 30 },
            nuts:   { brazil: 200, pecan: 173, almond: 37, cashew: 12, chestnut: 70 },
            shrimp: { arctic: 120, fresh_water: 20, atlantic: 72 } },
          employees: [
            Employee.new("John", "Sansk", "General Manager"),
            Employee.new("Sam", "Bogert", "Checkout Manager"),
            Employee.new("Gene", "Pollack", "Warehouse Manager"),
            Employee.new("Shane", "Leson", "Human Resources") ],
          address: '101 Big St',
          services: [:pharmacy, :groceries, :salon, :kids_corner, :pet_grooming]
        },
        springfield: {
          inventory: {
            apples: { golden_delicious: 220, fuji: 110, cameo: 101, honeycrisp: 75 },
            bread:  { white: 220, whole_wheat: 150, multigrain: 72, rye: 27 },
            fish:   { salmon: 101, trout: 97, snapper: 172, catfish: 17, cod: 93 },
            meat:   { ribeye: 13, chuck_roast: 82, flank_steak: 73, beef_brisket: 30 },
            nuts:   { mixed: 211, pistachio: 75, almond: 370, cashew: 121, trail_mix: 92},
            shrimp: { uncooked: 252, fresh_water: 72, atlantic: 93 } },
          employees: [
            Employee.new("Kerry",  "Adams",  "General Manager"),
            Employee.new("Jack", "Lenere", "Checkout Manager"),
            Employee.new("Sherry", "Nerst", "Warehouse Manager"),
            Employee.new("Ken", "Beson", "Human Resources") ],
          address: '220 Small St',
          services: [:groceries, :kids_corner]
        }
      }
    }
end
