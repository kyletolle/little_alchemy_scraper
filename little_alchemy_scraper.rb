require 'rubygems'
require 'mechanize'
require 'json'
require 'csv'

a = Mechanize.new do |agent|
  agent.user_agent_alias = 'Mac Safari'
end

BASE_URL = 'https://littlealchemy.com'
CHEATS_URL = "#{BASE_URL}/cheats"

ELEMENTS_FILE_NAME = 'elements.json'

elements =
  if File.exist?(ELEMENTS_FILE_NAME)
    JSON.parse(File.read(ELEMENTS_FILE_NAME))
  else
    {}
  end

cheats_page = a.get(CHEATS_URL)

elements_page = a.click(cheats_page.link_with(:text => /new hint/))

while elements.size < 560
  element_name = elements_page.search('div.mainElement div.elementBox').text

  if elements_page.uri.to_s =~ /popsicle/
    elements_page = a.click(elements_page.link_with(:text => /new hint/))
    next
  end

  puts "found element #{element_name}"

  unless elements[element_name]
    combinations_html = elements_page.search('div.combination')
    first_combination_html = combinations_html.first
    ingredient_names =
      first_combination_html.search('div.elementBox').map do |element_box|
        element_box.text
      end
    first_combination_text = ingredient_names.join(' + ')

    elements[element_name] = first_combination_text
    puts "adding #{element_name} a total of #{elements.size} found"
    File.open(ELEMENTS_FILE_NAME,'w') do |f|
      f.write(elements.to_json)
    end
    CSV.open('elements.csv', 'wb') do |csv|
      csv << ['element', 'ingredients']
      elements.each do |element, ingredients|
        csv << [element, ingredients]
      end
    end
  end

  elements_page = a.click(elements_page.link_with(:text => /new hint/))
end

