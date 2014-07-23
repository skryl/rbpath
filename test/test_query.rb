require_relative 'test_helper'
require_relative 'data/test_data'

describe RbPath::Query do
  before do
    @store_data = TestData::STORE_DATA
  end

  describe 'query parsing' do

    describe "single string queries" do

      it 'should identify a single key' do
        RbPath::Query.new("some_key").instance_variable_get('@query').must_equal \
          [{multi: false, neg: false, keys: ['some_key']}]
      end

      it 'should identify a list of keys' do
        RbPath::Query.new("one two three").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: ['two']},
            {multi: false, neg: false, keys: ['three']} ]
      end

      it 'should identify list of keys with quoted spaces' do
        RbPath::Query.new("one 'two and a half' three").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: ['two and a half']},
            {multi: false, neg: false, keys: ['three']} ]
      end

      it 'should identify ORed keys in a list' do
        RbPath::Query.new("one (two,three,four) ('twenty two','forty three')").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: ['two','three','four']},
            {multi: false, neg: false, keys: ['twenty two', 'forty three']} ]
      end

      it 'should identify NORed keys in a list' do
        RbPath::Query.new("one [two,three,four] ['fifty five','sixty six']").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: true,  keys: ['two','three','four']},
            {multi: false, neg: true, keys: ['fifty five', 'sixty six']} ]
      end

      it 'should identify splats' do
        RbPath::Query.new("one [] (two,three) * four").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: true,  keys: []},
            {multi: false, neg: false, keys: ['two', 'three']},
            {multi: false, neg: true,  keys: []},
            {multi: false, neg: false, keys: ['four']} ]
      end

      it 'should identify multi-splats' do
        RbPath::Query.new("one [] (two,three) ** four").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: true,  keys: []},
            {multi: false, neg: false, keys: ['two', 'three']},
            {multi: true,  neg: true,  keys: []},
            {multi: false, neg: false, keys: ['four']} ]
      end

      it 'should just work' do
        RbPath::Query.new("one [] ('twenty two',three) * () four [five,'sixty five'] 'seventy two' *").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: true,  keys: []},
            {multi: false, neg: false, keys: ['twenty two', 'three']},
            {multi: false, neg: true,  keys: []},
            {multi: false, neg: false, keys: []},
            {multi: false, neg: false, keys: ['four']},
            {multi: false, neg: true,  keys: ['five', 'sixty five']},
            {multi: false, neg: false, keys: ['seventy two']},
            {multi: false, neg: true,  keys: []} ]
      end
    end

    describe "multipart queries" do

      it 'should accept a multipart query and convert symbols to strings' do
        RbPath::Query.new(:one, 'two', :three).instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: ['two']},
            {multi: false, neg: false, keys: ['three']} ]
      end

      it 'should not convert other objects to strings in a multipart query' do
        RbPath::Query.new(:one, 2, 'three', nil).instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: [2]},
            {multi: false, neg: false, keys: ['three']},
            {multi: false, neg: false, keys: [nil]} ]
      end

      it 'should seperately parse all parts of a multipart query' do
        RbPath::Query.new("one (two,three)", :four, "[five,six] seven", "'eighty nine'").instance_variable_get('@query').must_equal \
          [ {multi: false, neg: false, keys: ['one']},
            {multi: false, neg: false, keys: ['two','three']},
            {multi: false, neg: false, keys: ['four']},
            {multi: false, neg: true,  keys: ['five','six']},
            {multi: false, neg: false, keys: ['seven']},
            {multi: false, neg: false, keys: ['eighty nine']} ]
      end
    end
  end

  describe 'query engine' do

    describe 'literal queries' do

      it 'should work on hashes and their leaf values' do
        RbPath::Query.new("illinois chicago inventory apples gala", 200).pquery(@store_data).must_match_array \
          [['illinois', 'chicago', 'inventory', 'apples', 'gala', 200]]
      end

      it 'should work on arrays and their leaf values' do
        RbPath::Query.new("illinois chicago services 0 pharmacy").pquery(@store_data).must_match_array \
          [['illinois', 'chicago', 'services', '0', 'pharmacy']]
      end

      it 'should work on rbpath objects and their leaf values' do
        RbPath::Query.new("illinois chicago employees 0 last Sansk").pquery(@store_data).must_match_array \
          [['illinois', 'chicago', 'employees', '0', 'last', 'Sansk']]
      end

      # leaf values should not be included in the main query if they are not strings
      #
      it 'should not match stringified leaf values' do
        RbPath::Query.new("illinois chicago inventory apples gala 200").pquery(@store_data).must_match_array []
      end

    end

    describe 'splat queries' do

      it 'should work on leaf values' do
        RbPath::Query.new("illinois chicago inventory apples gala *").pquery(@store_data).must_match_array \
          [['illinois', 'chicago', 'inventory', 'apples', 'gala', 200]]
      end

      it 'should work on hashes' do
        RbPath::Query.new("* * *").pquery(@store_data).must_match_array \
          [["illinois", "employees", "0"],
           ["illinois", "chicago", "inventory"],
           ["illinois", "chicago", "employees"],
           ["illinois", "chicago", "address"],
           ["illinois", "chicago", "services"],
           ["illinois", "springfield", "inventory"],
           ["illinois", "springfield", "employees"],
           ["illinois", "springfield", "address"],
           ["illinois", "springfield", "services"]]
      end


      it 'should work on arrays' do
        RbPath::Query.new("* chicago services *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0"],
           ["illinois", "chicago", "services", "1"],
           ["illinois", "chicago", "services", "2"],
           ["illinois", "chicago", "services", "3"],
           ["illinois", "chicago", "services", "4"]]
      end

      it 'should work on rbpath objects' do
        RbPath::Query.new("* chicago employees 0 *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "employees", "0", "first"],
           ["illinois", "chicago", "employees", "0", "last"],
           ["illinois", "chicago", "employees", "0", "position"]]
      end

    end

    describe 'OR queries' do

      it 'should work on hashes' do
        RbPath::Query.new("illinois chicago (services,employees) *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0"],
           ["illinois", "chicago", "services", "1"],
           ["illinois", "chicago", "services", "2"],
           ["illinois", "chicago", "services", "3"],
           ["illinois", "chicago", "services", "4"],
           ["illinois", "chicago", "employees", "0"],
           ["illinois", "chicago", "employees", "1"],
           ["illinois", "chicago", "employees", "2"],
           ["illinois", "chicago", "employees", "3"]]
      end

      it 'should work on arrays' do
        RbPath::Query.new("illinois chicago services (0,1) *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0", "pharmacy"],
           ["illinois", "chicago", "services", "1", "groceries"]]
      end

      it 'should work on rbpath objects' do
        RbPath::Query.new("illinois chicago employees * (first,last) *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "employees", "0", "first", "John"],
           ["illinois", "chicago", "employees", "0", "last", "Sansk"],
           ["illinois", "chicago", "employees", "1", "first", "Sam"],
           ["illinois", "chicago", "employees", "1", "last", "Bogert"],
           ["illinois", "chicago", "employees", "2", "first", "Gene"],
           ["illinois", "chicago", "employees", "2", "last", "Pollack"],
           ["illinois", "chicago", "employees", "3", "first", "Shane"],
           ["illinois", "chicago", "employees", "3", "last", "Leson"]]
      end
    end

    describe 'NOR queries' do

      it 'should work on hashes' do
        RbPath::Query.new("illinois chicago [inventory,address] *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0"],
           ["illinois", "chicago", "services", "1"],
           ["illinois", "chicago", "services", "2"],
           ["illinois", "chicago", "services", "3"],
           ["illinois", "chicago", "services", "4"],
           ["illinois", "chicago", "employees", "0"],
           ["illinois", "chicago", "employees", "1"],
           ["illinois", "chicago", "employees", "2"],
           ["illinois", "chicago", "employees", "3"]]
      end

      it 'should work on arrays' do
        RbPath::Query.new("illinois chicago services [2,3,4] *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0", "pharmacy"],
           ["illinois", "chicago", "services", "1", "groceries"]]
      end

      it 'should work on rbpath objects' do
        RbPath::Query.new("illinois chicago employees * [position] *").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "employees", "0", "first", "John"],
           ["illinois", "chicago", "employees", "0", "last", "Sansk"],
           ["illinois", "chicago", "employees", "1", "first", "Sam"],
           ["illinois", "chicago", "employees", "1", "last", "Bogert"],
           ["illinois", "chicago", "employees", "2", "first", "Gene"],
           ["illinois", "chicago", "employees", "2", "last", "Pollack"],
           ["illinois", "chicago", "employees", "3", "first", "Shane"],
           ["illinois", "chicago", "employees", "3", "last", "Leson"]]
      end
    end

    describe 'REGEX queries' do

      it 'should work on hashes' do
        RbPath::Query.new("illinois chicago inventory meat", /(pork.*|beef.*)/).pquery(@store_data).must_match_array \
          [["illinois", "chicago", "inventory", "meat", "pork_chop"],
           ["illinois", "chicago", "inventory", "meat", "pork_loin"],
           ["illinois", "chicago", "inventory", "meat", "beef_brisket"]]
      end

      it 'should work on arrays' do
        RbPath::Query.new("illinois chicago services", /[01]/, "*").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0", "pharmacy"],
           ["illinois", "chicago", "services", "1", "groceries"]]
      end

      it 'should work on rbpath objects' do
        RbPath::Query.new("illinois chicago employees *", /(first|last)/, /(Gene|Pollack)/).pquery(@store_data).must_match_array \
          [["illinois", "chicago", "employees", "2", "first", "Gene"],
           ["illinois", "chicago", "employees", "2", "last", "Pollack"]]
      end
    end

    describe 'Multilevel wildcard queries' do
      it 'should match no elements' do
        RbPath::Query.new("** illinois").pquery(@store_data).must_match_array \
          [["illinois"]]
      end

      it 'should match leaf nodes' do
        RbPath::Query.new("illinois chicago services 0 pharmacy **").pquery(@store_data).must_match_array \
          [['illinois','chicago','services','0','pharmacy']]
      end

      it 'should match with multiple multi-wildcards' do
        RbPath::Query.new("** chicago ** pharmacy").pquery(@store_data).must_match_array \
          [['illinois','chicago','services','0','pharmacy']]
      end

      it 'should work on hashes' do
        RbPath::Query.new("**", /(pork.*|beef.*)/).pquery(@store_data).must_match_array \
          [["illinois", "chicago", "inventory", "meat", "pork_chop"],
           ["illinois", "chicago", "inventory", "meat", "pork_loin"],
           ["illinois", "chicago", "inventory", "meat", "beef_brisket"],
           ["illinois", "springfield", "inventory", "meat", "beef_brisket"]]
      end

      it 'should work on arrays' do
        RbPath::Query.new("** services", /[01]/, "*").pquery(@store_data).must_match_array \
          [["illinois", "chicago", "services", "0", "pharmacy"],
           ["illinois", "chicago", "services", "1", "groceries"],
           ["illinois", "springfield", "services", "0", "groceries"],
           ["illinois", "springfield", "services", "1", "kids_corner"]]
      end

      it 'should work on rbpath objects' do
        RbPath::Query.new("**", /(first|last)/, /(Gene|Pollack)/).pquery(@store_data).must_match_array \
          [["illinois", "chicago", "employees", "2", "first", "Gene"],
           ["illinois", "chicago", "employees", "2", "last", "Pollack"]]
      end
    end
  end

  describe 'classes which include the RbPath mixin' do

    before do
      @employee = TestData::Employee.new('Alex', 'Skryl', 'CEO')
      @employee_class = TestData::Employee.dup
    end

    it 'should be rbpath' do
      @employee.must_be_kind_of(RbPath)
    end

    it 'should return its rbpath fields' do
      @employee.rbpath_fields.must_equal ['first', 'last', 'position']
      @employee.class.rbpath_fields.must_equal ['first', 'last', 'position']
    end

    it 'should be able to set rbpath fields' do
      @employee_class.class_eval do
        rbpath :one, :two, :three
      end
      @employee_class.rbpath_fields.must_equal ['one', 'two', 'three']
      @employee_class.new.rbpath_fields.must_equal ['one', 'two', 'three']
    end

    it 'should have instances that are able to query themselves' do
      @employee.must_respond_to(:pquery)
      @employee.pquery("first *").must_equal [['first', 'Alex']]
    end

    it 'should have instances that are able to fetch values' do
      @employee.must_respond_to(:path_values)
      @employee.path_values([['first','Alex']]).must_equal ['Alex']
    end
  end

  describe 'singletons which extend the RbPath mixin' do

    before do
      @hash = {first: 'Alex', last: 'Skryl', age: '100', address: '101 blah st'}
      @hash.extend RbPath
    end

    it 'should be able to query itself' do
      @hash.must_respond_to(:query)
      @hash.pquery("first *").must_equal [['first', 'Alex']]
    end

    it 'should have instances that are able to fetch values' do
      @hash.must_respond_to(:path_values)
      @hash.path_values([['first','Alex']]).must_equal ['Alex']
    end

    it 'should have no rbpath fields' do
      @hash.rbpath_fields.must_equal nil
    end
  end

end
