#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    member_rows.map do |row|
      data = fragment(row => MemberRow).to_h
      data[:party_id] = parties[data[:party]]
      data
    end
  end

  private

  def member_table
    noko.xpath('//h2[span[@id="Abgeordnete"]]//following-sibling::table[1]')
  end

  def member_rows
    member_table.xpath('.//tr[td]')
  end

  def parties
    @parties ||= noko.css('.thumbinner li a').map { |a| [a.text, a.attr('wikidata')] }.to_h
  end
end

class MemberRow < Scraped::HTML
  field :name do
    name_link.text.tidy
  end

  field :id do
    name_link.attr('wikidata')
  end

  field :party do
    tds[5].text.tidy
  end

  field :constituency do
    tds[6].css('a').map(&:text).map(&:tidy).first
  end

  field :constituency_id do
    tds[6].css('a/@wikidata').map(&:text).first
  end

  private

  def tds
    noko.css('td')
  end

  def name_link
    tds[0].at_css('a')
  end
end

url = 'https://de.wikipedia.org/wiki/Liste_der_Abgeordneten_zum_%C3%96sterreichischen_Nationalrat_(XXVI._Gesetzgebungsperiode)'
Scraped::Scraper.new(url => MembersPage).store(:members)
