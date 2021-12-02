# frozen_string_literal: true

require 'set'
require 'terminal-table'

def words
  word1 = 'caaadbebeb'
  word_sam = 'bacbcbcde'
  [word1, word_sam]
end

def test_grammar
  grammar1 = ['S -> ASb | C',
               'A -> a',
               'C -> cC | #']
  grammar19 = ['S -> LdX',
                   'X -> D',
                   'L -> caY',
                   'Y -> # | aY',
                   'D -> bZ',
                   'Z -> # | ebZ']
  grammar_sam = ['S -> Ae',
                 'A -> bcL',
                 'L -> Ed',
                 'E -> DF',
                 'F -> # | bDF',
                 'D -> a'
               ]
  [grammar1, grammar19, grammar_sam]
end

puts 'Grammar (# for EPS): '
puts grammar = test_grammar[2]
puts ''

def give_productions(grammar, no_productions)
  productions = {}
  no_productions.times do |i|
    production = grammar[i].split
    rhs = []
    rhsx = []
    (2...production.size).each do |j|
      if production[j] != '|'
        rhsx.append(production[j])
      else
        rhs.append(rhsx)
        rhsx = []
      end
    end
    rhs.append(rhsx)
    productions[production[0]] = rhs
  end
  productions
end

def first(s, productions)
  c = s[0]
  ans = Set.new
  # If X is terminal, FIRST(X) = {X}
  # Also includes ε in first{} for a production rule A → ε
  if c == c.downcase
    ans |= Set[c]
  # If X is a NT & X → Y1Y2Y3..Yk
  else
    productions[c].each do |rhs|
      # If ε ∈ FIRST(Y1), then FIRST(X) = FIRST(Y1)
      if rhs == '#'
        ans |= Set['#']
      # If ε ∉ FIRST(Y1), then FIRST(X) = {FIRST(Y1) - ε} ∪ FIRST(Y2Y3)
      else
        f = first(rhs, productions)
        f.map { |x| ans |= Set[x] }
      end
    end
  end
  ans
end

def follow(s, productions, ans)
  s == productions.first[0] ? ans[s] = Set["$"] : ans[s] = Set.new

  productions.each_pair do |lhs, rhs|
    for value in rhs
      idx = value.index(s)
      if idx != nil && idx == value.size-1
          if lhs != s
            if ans.has_key?(lhs)
              tmp = ans[lhs]
            else
              ans = follow(lhs, productions, ans)
              tmp = ans[lhs]
            end
            ans[s] |= tmp
          end
      elsif idx != nil && idx != value.size-1
          first_of_next = first(value[idx+1..value.size], productions)
          return ans[s] |= first_of_next unless first_of_next === '#'
          if ans.has_key?(lhs)
            tmp = ans[lhs]
          else
            ans = follow(lhs, productions, ans)
            tmp = ans[lhs]
          end
          ans[s] |= tmp
          ans[s] |= first_of_next - Set['#']
      end
    end
  end
  ans
end

def give_parsing_table(productions, first, follow)
  table = {}
  productions.each_pair do |lhs, rhs|
    for x in rhs
      if x.chr == x.chr.downcase
        if x.chr == '#'
          follow[lhs].map { |f| table.merge!([lhs, f] => x) }
        else
          table.merge!([lhs, x.chr] => x)
        end
      else
        first[x.chr].map { |f| table.merge!([lhs, f] => x) }
      end
    end
  end
  table
end

def parse(table, start_symb, word)
  rows = []
  flag = 0
  word += "$"
  stack = []
  stack.append("$")
  stack.append(start_symb)
  idx = 0
  while stack.size > 0
    row = []
    row << stack.flatten.reverse
    top = stack[stack.size-1]
    curr_input = word[idx]
    row << word[idx, word.size]
    if top == curr_input
      row << "pop " + stack.pop()
      idx += 1
    else
      key = [top, curr_input]
      if !table.include?(key)
        flag = 1
        break
      end
      value = table[key]
      row << value
      if value != '#'
        value = value.chars.reduce{|s,c| c + s }.chars # reverse str
        stack.pop()
        value.map { |element| stack.append(element) }
      else
        stack.pop()
      end
    end
    rows << row
  end
  tablle = Terminal::Table.new :title => "w = #{word}", :headings => ['STACK', 'INPUT', 'OUTPUT'], :rows => rows
  puts tablle
  puts flag == 0 ? "\t"*5+"\s\sSTRING ACCEPTED\n" : "\t"*4+"STRING NOT ACCEPTED\n"
end

productions = Hash[grammar.each.map { |value| [value[0], Set[*value[1..].scan(/[^->|\s]+/)]] }]

first_hash = {}
follow_hash = {}

productions.each_pair do |lhs, _rhs|
  first_hash[lhs] = first(lhs, productions)
end

puts "FIRST\n\n"
pp first_hash

productions.each_pair do |lhs, rhs|
  follow_hash[lhs] = Set.new
end

productions.each_pair do |lhs, _rhs|
  follow_hash[lhs] << follow(lhs, productions, follow_hash)
end

puts "\nFOLLOW\n\n"
pp follow_hash

ll1_table = give_parsing_table(productions, first_hash, follow_hash)

puts "\nLL(1) table\n\n"
pp ll1_table

print "\nEnter the string:\t"
word = words[1]
p word

start_symb = productions.first[0]
parse(ll1_table, start_symb, word)