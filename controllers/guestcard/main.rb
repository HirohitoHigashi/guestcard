#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# 来場者記録
#

require "al_form"
require "al_template"
require "al_mif"
require_relative "./guest"

class GuestsController < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlInteger.new( "id", :foreign=>true ),
      AlDate.new( "created_at", :label=>"登録日", :foreign=>true ),
      AlText.new( "name", :label=>"氏名", :required=>true ),
      AlInteger.new( "number", :label=>"人数", :value=>1, :required=>true ),
      AlText.new( "organization", :label=>"所属" ),
      AlRadios.new( "purpose", :label=>"ご用件", :required=>true,
        :options=>{ "制度利用相談"=>"制度利用相談",
                    "技術相談"=>"技術相談",
                    "事業等打合せ"=>"事業等打合せ",
                    "その他"=>"その他" }),
      AlText.new( "purpose_option", :label=>"ご用件（自由入力）" ),
      AlText.new( "person", :label=>"ITOC担当" ),
      AlSubmit.new( "submit1", :value=>"決定",
        :tag_attr=> {:style=>"float: right;"} )
    )

    @persist = Guest.new
  end


  ##
  # 新規登録フォーム表示
  #
  def action_create
    log "CREATE"
    @part_template = "guestcard/_create.html"
    @template_create = "layouts/application.html"
#    super()
    AlTemplate.run("layouts/application.html")
  end
  alias action_index action_create



  ##
  # 新規登録
  #
  def action_create_submit
    log "CREATE_SUBMIT"

    @part_template = "guestcard/_create_submit.html"
    @template_create_submit = "layouts/application.html"
    super()
#    AlTemplate.run("layouts/application.html")
  end



  ##
  # 一覧表示
  #
  def action_list()
    @year = Time.now.year()
    @month = Time.now.month()

    # 検索条件の取得および調整
    form_search_condition = AlForm.new(
      AlInteger.new( "total_rows", :min=>0 ),
      AlInteger.new( "offset", :min=>0 ),
      AlInteger.new( "year"),
      AlInteger.new( "month", :min=>1),
      AlText.new( "order_by", :validator=>/\A[\w ]+\z/ )
    )

    @search_condition ||= {}
    if form_search_condition.validate()
      if @search_condition[:total_rows] && form_search_condition[:total_rows]
        @search_condition[:total_rows] = form_search_condition[:total_rows].to_i
      end
      @search_condition[:offset] ||= form_search_condition[:offset].to_i
      if ! form_search_condition[:order_by].empty?
        @search_condition[:order_by] ||= form_search_condition[:order_by]
      end
    end

    @search_condition[:limit] ||= 20
    @search_condition[:order_by] = ["created_at"]

    if form_search_condition[:year].to_i > 0
      @year = form_search_condition[:year].to_i
    end
    #puts form_search_condition[:year].to_i

    if form_search_condition[:month].to_i > 0
      @month = form_search_condition[:month].to_i
      if @month > 12
        @year += 1
        @month = 1
      end
    end
    #puts form_search_condition[:month].to_i

    # データの取得
    #@datas = @persist.search( @search_condition )
    @datas = @persist.select( "*", "from guests where created_at between '#{@year}-0#{@month}%' AND '#{@year}-0#{@month + 1}%' ", {} )
    #puts "from guests where created_at between '#{@year}-0#{@month}%' AND '#{@year}-0#{@month + 1}%' "

    # 表示用カラム配列作成
    @columns = []
    @form.widgets.each do |k,w|
      next if w.class == AlHidden || w.class == AlSubmit || w.class == AlPassword || w.hidden
      @columns << k
    end

    # 次のリクエストURI生成用インスタンス変数@requestを作る
    @request = AlForm.request_get
    if @persist.search_condition[:total_rows]
      @request[:total_rows] = @persist.search_condition[:total_rows]
    end

    # 表示開始
    #AlTemplate.run( @template_list || "#{AL_BASEDIR}/templates/list.rhtml" )
    AlTemplate.run("layouts/_list.rhtml")
  end



  ##
  # CSVファイルの送信
  #
  def action_csv()
    @year = Time.now.year()
    @month = Time.now.month()

    # 検索条件の取得および調整
    form_search_condition = AlForm.new(
      AlInteger.new( "total_rows", :min=>0 ),
      AlInteger.new( "offset", :min=>0 ),
      AlInteger.new( "year"),
      AlInteger.new( "month", :min=>1),
      AlText.new( "order_by", :validator=>/\A[\w ]+\z/ )
    )

    @search_condition ||= {}
    if form_search_condition.validate()
      if @search_condition[:total_rows] && form_search_condition[:total_rows]
        @search_condition[:total_rows] = form_search_condition[:total_rows].to_i
      end
      @search_condition[:offset] ||= form_search_condition[:offset].to_i
      if ! form_search_condition[:order_by].empty?
        @search_condition[:order_by] ||= form_search_condition[:order_by]
      end
    end

    @search_condition[:limit] ||= 20
    @search_condition[:order_by] = ["created_at"]

    if form_search_condition[:year].to_i > 0
      @year = form_search_condition[:year].to_i
    end
    #puts form_search_condition[:year].to_i

    if form_search_condition[:month].to_i > 0
      @month = form_search_condition[:month].to_i
      if @month > 12
        @year += 1
        @month = 1
      end
    end
    #puts form_search_condition[:month].to_i

    # データの取得
    @datas = @persist.select( "*", "from guests where created_at between '#{@year}-0#{@month}%' AND '#{@year}-0#{@month + 1}%' ", {} )

    # 表示用カラム配列作成
    @columns = []
    @form.widgets.each do |k,w|
      next if w.class == AlHidden || w.class == AlSubmit || w.class == AlPassword || w.hidden
      @columns << k
    end

    csv = ""

    @datas.each do |d|
      @columns.each do |k|
        #@csv += d.to_s
        csv += @form.widgets[k].make_value( d[k] ) + ","
      end
      csv += "\n"
    end

    Alone.add_http_header("Content-Type: text/csv; charset=UTF-8")
    Alone::add_http_header( "Content-Disposition: attachment; filename=#{@year}-#{@month}.csv" )
    puts csv
  end
end
