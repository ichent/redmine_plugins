# SubsController
#
# Controller for working with subscriptions

require 'authorize_net'

class SubsController < ApplicationController
  unloadable

  before_filter :find_account

  helper :credit_card
  include CreditCardHelper
  helper :subs_sort
  include SubsSortHelper

  def index
    if !User.current.admin?
      redirect_to :controller => "account", :action => "login"
    end

    sort_init 'date', 'desc'
    sort_update %w(date user_message amount)

    # Find a payments
    @payment_count = TransactionCC.count(:conditions => ["i_account = ?", @account.i_account])
    @payment_pages = Paginator.new self, @payment_count, per_page_option, params['page']
    @payments = TransactionCC.find(:all, :conditions => ["i_account = ?", @account.i_account],
                                         :order => sort_clause,
                                         :limit => per_page_option,
                                         :offset =>  @payment_pages.current.offset)

    if request.xhr?
      render :template => 'trans/index', :layout => false
      return false
    end

    @country = Country.find(:all).map {|p| p.country}
    @state = State.find(:all).map {|p| p.state}

    unless params[:tab].blank?
      @selected_tab = case params[:tab]
        when "subscription"
          "tab-content-subscription"
        when "payments"
          "tab-content-payments"
        when "subscriber"
          "tab-content-subscriber"
        else
          "tab-content-subscription"
      end
    else
      @selected_tab = "tab-content-subscription"
    end

    #@account = Account.find($uid)

    #ccplan = (Subscription.count :conditions => "active=1 and i_account=#{$uid}").to_i == 0 ? 0 : @account.plan["i_plan"]
    #@plans = PlanCC.find(:all, :conditions => "i_plan!=#{ccplan} and active=1 and and billcycle=\"#{@account.plan["billcycle"]}\"", :order => "i_plan")
    @plans = PlanCC.find(:all, :order => "i_plan")
    @cur_plan = @account.plan
    if @account.i_bilcircle == 0
      @bil_circle = BillingCircle.find(:first, :conditions => "bilcircle = 12")
      @cur_price = @cur_plan.price
    else
      @bil_circle = @account.billingcircle
      @cur_price = (@cur_plan.price*@bil_circle.bilcircle).to_f*((100-@bil_circle.discount).to_f/100)
    end

    @ncur_plan = Plan.find_by_i_plan(@cur_plan["i_plan"], :conditions => "active=1 and modify=1 and billcycle!=\"#{@cur_plan["billcycle"]}\"")
    @subscription = Subscription.find_by_i_account($uid, :conditions => "active=1")

    # Find a credit card
    @credit_card = CreditCard.find_by_i_cc(@account.i_cc)

    # Encode values
    @credit_card.first_name = decode_value(@credit_card.first_name).to_s.strip
    @credit_card.last_name = decode_value(@credit_card.last_name).to_s.strip
    @credit_card.cc_number = decode_value(@credit_card.cc_number).to_s.strip
    @credit_card.address = decode_value(@credit_card.address).to_s.strip
    @credit_card.cc_expired = decode_value(@credit_card.cc_expired).to_s.strip
    @credit_card.address1 = decode_value(@credit_card.address1).to_s.strip

    @credit_card.address = @credit_card.address + @credit_card.address1    

    # Get a expires years and months
    time = Time.new
    @expires_years = Array.new
    (time.year..time.year+10).to_a.map do |year|
      @expires_years << year.to_s
    end

    @expires_months = Array.new
    Date::MONTHNAMES.each_with_index do |item, index|
      @expires_months << index.to_s + " - " + item unless item.nil?
    end

    if request.post?
      @selected_tab = "tab-content-subscriber"
      @plan = @account.i_plan
      @account.attributes = params[:account]
      @account.state = "--" if @account.country != "United States of America"
      @account.i_plan = @plan

      if @account.save
          flash.now[:notice] = 'Successfully saved'

          # Add transaction
          add_transaction(:i_account => @account.i_account,
                          :i_cc => @credit_card.i_cc,
                          :type => "cc_changed",      
                          :user_message => "Account information changed",
                          :ip => request.remote_ip.to_s)
      end
    end
  end

  # Save a credit card
  def card
    if request.post?
      # Save information in DB
      # Update attributes of credit card        
      @credit_card = CreditCard.new(params[:credit_card])
      @credit_card.type = ""
      @credit_card.i_account = $uid

      # Override a state
      if params[:state].blank?
        @credit_card.state = "--"
      end

      # Convert a date expired
      expired_date = params[:expires_date_months].[](0..1).strip.concat(params[:expires_date_years].[](2..3))
      if expired_date.length == 3
        expired_date = "0".concat(expired_date)
      end

      cc_expired = expired_date.[](0..1) + "/" + expired_date.[](2..3)
      @credit_card.cc_expired = cc_expired

      # Validation a credit card
      unless @credit_card.valid?
        flash_error = "<ul>"
        @credit_card.errors.full_messages.each do |curr_error|
          flash_error << "<li>" << curr_error.to_s << "</li>"
        end
        flash_error << "</ul>"

        flash[:error_card] = flash_error

        redirect_to :controller => 'subs', :tab => "subscriber"
        return false
      end

      # Encode values
      @credit_card.first_name = encode_value(@credit_card.first_name).to_s.strip
      @credit_card.last_name = encode_value(@credit_card.last_name).to_s.strip
      @credit_card.cc_number = encode_value(@credit_card.cc_number).to_s.strip
      @credit_card.address = encode_value(@credit_card.address).to_s.strip
      @credit_card.cc_expired = encode_value(@credit_card.cc_expired).to_s.strip
      #@credit_card.address1 = encode_value(@credit_card.address1)

      # First, check by Luhn-algoritm
      # Checks cc by luhn alrogithm
      unless check_luhn(params[:credit_card][:cc_number])
        redirect_to :controller => 'subs', :tab => "subscriber"
        return false
      end

      # Checks, is ip blocked
      unless check_blocked_ip
        redirect_to :controller => 'subs', :tab => "subscriber"
        return false
      end

      # Checks cc by authorize.net
      unless authorize_net_valid(params[:credit_card])
        redirect_to :controller => 'subs', :tab => "subscriber"
        return false
      end

      # Clear cvv of credit card
      @credit_card.cvv = ""

      # Save the credit card
      if @credit_card.save        
        # Update a card_id in the Account
        @account.attributes = {:i_cc => @credit_card.i_cc}
        @account.save

        # Generate user message
        if @response_code.to_i == 1 && @response_reason_code.to_i == 1
          user_message = "Billing information changed"
        else
          user_message = get_user_message(@response_code, @response_reason_code)
        end

        # Add transaction
        add_transaction(:i_account => @account.i_account,
                        :i_cc => @credit_card.i_cc,
                        :type => "cc_changed",
                        :transaction_id => @authorize_transaction_id,
                        :gw_string => @authorize_gateway,
                        :user_message => user_message,
                        :ip => request.remote_ip.to_s,
                        :authorization_code => @authorize_code)

        # Clear session
        session[:count_card_validation] = nil

        flash[:notice] = 'Credit card saved successfully'

        # Check, if account is blocked, then try to make a purchase and unblock account
        # Find a account
        @account = Account.find($uid)

        if @account.active == 0 && (Time.now.to_i-@account.endtime.to_i) > (60*60*24*3)
          bil_circle = @account.i_bilcircle
          @bil_circle = BillingCircle.find_by_i_bilcircle(bil_circle) if bil_circle > 0

          # Credit of user
          #credit = (@account.credit > 0) ? @account.credit : 0

          @plan = PlanCC.find_by_i_plan(@account.i_plan)

          # Count months of subscription
          count_months = (bil_circle == 0) ? 1 : @bil_circle.bilcircle
          # Discount of subscription
          discount = (bil_circle == 0) ? 0 : @bil_circle.discount.to_f/100

          # Find a credit card
          @credit_card = CreditCard.find_by_i_cc(@account.i_cc)
          # Result sum of payment
          sum_purchase = (@plan.price*count_months) - (@plan.price*count_months*discount) - @account.credit

          if sum_purchase > 0
            # Make a payment
            payment_result = authorize_net_purchase(sum_purchase)

            # Generate user message
            if @response_code.to_i == 1 && @response_reason_code.to_i == 1
              user_message = "Billing information changed"
            else
              user_message = get_user_message(@response_code, @response_reason_code)
            end

            if payment_result
              # Enable account
              @account.active = 1
              @account.credit = 0
              @account.endtime = (count_months.months).since(Time.now) #@account.endtime)

              @account.save

              add_transaction(:i_account => @account.i_account,
                              :i_cc => @credit_card.i_cc,
                              :amount => sum_purchase,
                              :type => "payment_received",
                              :transaction_id => @authorize_transaction_id,
                              :gw_string => @authorize_gateway,
                              :plan => @plan.i_plan,
                              :new_plan => @plan.i_plan,
                              :user_message => user_message,
                              :ip => request.remote_ip.to_s,
                              :authorization_code => @authorize_code)

              flash[:notice] = 'Credit card saved, account activated'
            else
              add_transaction(:i_account => @account.i_account,
                              :i_cc => @credit_card.i_cc,
                              :amount => sum_purchase,
                              :type => "payment_failed",
                              :transaction_id => @authorize_transaction_id,
                              :gw_string => @authorize_gateway,
                              :plan => @plan.i_plan,
                              :new_plan => @plan.i_plan,
                              :user_message => user_message,
                              :ip => request.remote_ip.to_s,
                              :authorization_code => @authorize_code)

              flash[:error_card] = 'Payment failed'
            end
          else
            # Sum purchase is less than 0
            sum_purchase = (@plan.price*count_months) - (@plan.price*count_months*discount)

            # Enable account
            @account.active = 1
            @account.endtime = (count_months.months).since(Time.now) #@account.endtime)
            @account.credit = @account.credit - sum_purchase

            @account.save

            add_transaction(:i_account => @account.i_account,
                            :i_cc => @credit_card.i_cc,
                            :amount => sum_purchase,
                            :type => "payment_received",
                            :plan => @plan.i_plan,
                            :new_plan => @plan.i_plan,
                            :user_message => "Billing information changed",
                            :ip => request.remote_ip.to_s)

            flash[:notice] = 'Credit card saved, account activated'
          end
        end
      else
        flash[:error_card] = @credit_card.errors.full_messages.to_sentence
      end

      redirect_to :controller => 'subs', :tab => "subscriber"
    else
      redirect_to :controller => 'subs'
    end
  end

  # Change current plan from year-to-month, month-to-year
  def change_plan
    if @account.active == 1
      # Find a plan,
      old_plan = PlanCC.find_by_i_plan(@account.i_plan)
      new_plan = PlanCC.find_by_i_plan(params[:plan])

      if !params[:type].blank?
        type = params[:type].to_s

        if !params[:year].blank?
          year = params[:year].to_i
        else
          flash[:error_card] = 'Incorrect parameters when changing the plan'
          redirect_to :controller => 'subs'
        end

        if type == "new"
          year = year == 1 ? true : false
        elsif type == "change"
          year = @account.i_bilcircle == 0 ? true : false
        else
          flash[:error_card] = 'Incorrect parameters when changing the plan'
          redirect_to :controller => 'subs' and return false
        end
      else
        flash[:error_card] = 'Incorrect parameters when changing the plan'
        redirect_to :controller => 'subs' and return false
      end

      # Calculate price of new plan
      @new_price = year ? calculate_discount_plan_cost(new_plan.i_plan) : new_plan.price
      @old_price = @account.i_bilcircle == 0 ? old_plan.price : calculate_discount_plan_cost(old_plan.i_plan)

      # Find a credit card
      @credit_card = CreditCard.find_by_i_cc(@account.i_cc)

      # Change plan
      #if @new_price > @old_price
        if year
          sum = @new_price - @account.credit

          if sum > 0
            # Make a payment
            payment_result = authorize_net_purchase(sum)

            # Generate user message
            if @response_code.to_i == 1 && @response_reason_code.to_i == 1
              user_message = "Plan changed"
            else
              user_message = get_user_message(@response_code, @response_reason_code)
            end

            if payment_result
              # Update account
              @account.endtime = (12.months).since(Time.now)
              @account.credit = 0
              @account.i_plan = new_plan.i_plan
              @account.i_bilcircle = BillingCircle.find(:first, :conditions => "bilcircle = 12").i_bilcircle
              @account.save

              add_transaction(:i_account => @account.i_account,
                              :i_cc => @credit_card.i_cc,
                              :amount => sum,
                              :type => "payment_received",
                              :plan => old_plan.i_plan,
                              :new_plan => new_plan.i_plan,
                              :transaction_id => @authorize_transaction_id,
                              :user_message => user_message,
                              :gw_string => @authorize_gateway,
                              :ip => request.remote_ip.to_s,
                              :authorization_code => @authorize_code)

              flash[:notice] = 'Plan changed'
            else
              add_transaction(:i_account => @account.i_account,
                              :i_cc => @credit_card.i_cc,
                              :amount => sum,
                              :type => "payment_failed",
                              :plan => old_plan.i_plan,
                              :new_plan => new_plan.i_plan,
                              :user_message => user_message,
                              :transaction_id => @authorize_transaction_id,
                              :gw_string => @authorize_gateway,
                              :ip => request.remote_ip.to_s,
                              :authorization_code => @authorize_code)

              flash[:error_card] = 'Payment failed'

              redirect_to :controller => 'subs' and return false
            end
          else
            @account.credit = @account.credit - @new_price
            @account.i_bilcircle = BillingCircle.find(:first, :conditions => "bilcircle = 12").i_bilcircle
            @account.i_plan = new_plan.i_plan
            @account.save

            # Add transaction
            add_transaction(:i_account => @account.i_account,
                            :i_cc => @credit_card.i_cc,
                            :type => "plan_changed",
                            :amount => @new_price,
                            :plan => old_plan.i_plan,
                            :new_plan => new_plan.i_plan,
                            :user_message => "Plan changed",
                            :new_plan => new_plan.i_plan,
                            :ip => request.remote_ip.to_s)
          end
        else
          # Add credit
          credit = 0 - ((@new_price-@old_price).to_f/30*(30-Time.now.day).abs)
          credit = 0 if credit > 0

          @account.credit = @account.credit + credit
          @account.endtime = (1.months).since(Time.now)
          @account.i_bilcircle = 0
          @account.i_plan = new_plan.i_plan
          @account.save

          # Add transaction
          add_transaction(:i_account => @account.i_account,
                          :i_cc => @credit_card.i_cc,
                          :type => "plan_changed",
                          :amount => credit,
                          :plan => old_plan.i_plan,
                          :new_plan => new_plan.i_plan,
                          :user_message => "Plan changed",
                          :new_plan => new_plan.i_plan,
                          :ip => request.remote_ip.to_s)
        end

        # Send Email
        Mailer.deliver_payment_success

        flash[:notice] = "Plan changed"
      #end
    end

    redirect_to :controller => 'subs'
  end

  # Change current plan from year-to-month, month-to-year
  def cancel_account
    @account.active = 0
    @account.endtime = Time.now
    @account.save
    
    redirect_to :controller => 'subs' and return false
  end
private
  def rescue_action(exception)
    logger.info "========rescue: " + exception.inspect
    render_404
  end

  # Check a cc by Luhn Algorithm
  def check_luhn(s)
    s.gsub!(/[^0-9]/, "")
    ss = s.reverse.split(//)

    alternate = false
    total = 0
    ss.each do |c|
      if alternate
        i = c.to_i*2
        total += (i > 9) ? (i % 10 + 1) : i
      else
        total += c.to_i
      end
      alternate = !alternate
    end

    result_check = (total % 10) == 0

    unless result_check
      # Card is invalid(luhn algorithm)
      flash[:error_card] = 'Card is not valid'

      # Block in session
      block_ip_in_session

      # Add transaction
      add_transaction(:i_account => $uid,
                      :i_cc => @credit_card.i_cc,
                      :type => "payment_refund",
                      :ip => request.remote_ip.to_s)

      #redirect_to :controller => 'subs', :action => 'index'
      false
    else
      true
    end
  end

  # Check a cc by AuthorizeNet
  def authorize_net_valid(options)
    transaction = AuthorizeNet::AIM::Transaction.new($api_login, $api_key, :gateway => $gateway.to_s.to_sym,
                                                                           :encapsulation_character => "|",
                                                                           :allow_split => true)

    # Find a state
    if params[:state].blank?
      state = "--"
    else
      state = State.find_by_state(options[:state]).state_abbr
    end    

    # Add address to request
    address = AuthorizeNet::Address.new(:first_name => options[:first_name],
                                        :last_name => options[:last_name],
                                        :street_address => options[:address],
                                        :city => options[:city],
                                        :state => state,
                                        :zip => options[:zip],
                                        :country => options[:country])
    transaction.set_address(address)

    # Convert a date expired
    expired_date = params[:expires_date_months].[](0..1).strip.concat(params[:expires_date_years].[](2..3))
    if expired_date.length == 3
      expired_date = "0".concat(expired_date)
    end

    # Add credit card to request
    credit_card = AuthorizeNet::CreditCard.new(options[:cc_number], expired_date, :card_code => options[:cvv])
    # Execute a request
    response = transaction.authorize(0.0, credit_card)

    # Get a result of request
    @authorize_transaction_id = response.transaction_id
    #@authorize_gateway = transaction.gateway
    @authorize_gateway = response.raw.body
    @authorize_code = response.authorization_code
    @response_code = response.response_code
    @response_reason_code = response.response_reason_code

    # Generate user message
    if @response_code.to_i == 1 && @response_reason_code.to_i == 1
      user_message = "Billing information changed"
    else
      user_message = get_user_message(@response_code, @response_reason_code)
    end

    unless response.success?
      # Card is invalid(authorize.net)
      flash[:error_card] = 'Can\'t authorize credit card'

      # Block in session
      block_ip_in_session

      # Add transaction
      add_transaction(:i_account => @account.i_account,                      
                      :type => "payment_refund",
                      :transaction_id => @authorize_transaction_id,
                      :gw_string => @authorize_gateway,
                      :user_message => user_message,
                      :ip => request.remote_ip.to_s,
                      :authorization_code => @authorize_code)
     
      false
    else
      true
    end
  end

  # Purchase
  def authorize_net_purchase(sum)
    transaction = AuthorizeNet::AIM::Transaction.new($api_login, $api_key, :gateway => $gateway.to_s.to_sym,
                                                                           :encapsulation_character => "|",
                                                                           :allow_split => true)
    
    # Find a credit card
    account_credit_card = @account.creditcard

    # Find a state
    if account_credit_card.state == "--"
      state = "--"
    else
      state = State.find_by_state(account_credit_card.state).state_abbr
    end

    exp_date = decode_value(account_credit_card.cc_expired).split('/').[](0..1).to_s

    credit_card = AuthorizeNet::CreditCard.new(decode_value(account_credit_card.cc_number), exp_date)

    # Add address to request
    address = AuthorizeNet::Address.new(:first_name => decode_value(account_credit_card.first_name),
                                        :last_name => decode_value(account_credit_card.last_name),
                                        :street_address => decode_value(account_credit_card.address) + decode_value(account_credit_card.address1),
                                        :city => account_credit_card.city,
                                        :state => state,
                                        :zip => account_credit_card.zip,
                                        :country => account_credit_card.country)
    transaction.set_address(address)

    response = transaction.purchase(sum, credit_card)

    # Get params from response
    @authorize_transaction_id = response.transaction_id
    #@authorize_gateway = transaction.gateway
    @authorize_gateway = response.raw.body
    @authorize_code = response.authorization_code
    @response_code = response.response_code
    @response_reason_code = response.response_reason_code

    if response.success?
      true
    else
      false
    end
  end

  # Add transaction to DB
  def add_transaction(options) #i_account, i_cc, type, t_id, gw_string, ip, auth_code)
    # Define a attributes
    attr = {:i_account => 0,
            :i_cc => 0,
            :amount => 0,
            :date => Time.now,
            :type => "",
            :transaction_id => 0,
            :gw_string => "",
            :note => "",
            :plan => 0,
            :new_plan => 0,
            :ip => "",
            :user_message => "",
            :authorization_code => ""}

    # Add transaction
    @transaction_cc = TransactionCC.new(attr.merge(options))

    @transaction_cc.save
  end

  # Block IP in session
  def block_ip_in_session
    # Checks, exists or not
    if session[:count_card_validation].blank?
      session[:count_card_validation] = 1
    elsif session[:count_card_validation] < 2
      # Increment a count of validation
      session[:count_card_validation] += 1
    else
      # Set inactive the account
      @account.attributes = {:active => 0}
      @account.save

      # Clear session
      session[:count_card_validation] = nil

      # Add ip to blocked ip
      @blocked_ip = BlockedIp.new(:ip => request.remote_ip)
      @blocked_ip.save
    end
  end

  # Calculate cost of plan
  def calculate_discount_plan_cost(plan_id)
    # Find a plan
    plan = PlanCC.find_by_i_plan(plan_id)
    # Find a discount
    discount = BillingCircle.find(:first, :conditions => "bilcircle = 12")

    # Calculate a prices
    (plan.price*discount.bilcircle).to_f*((100-discount.discount).to_f/100)
  end

  # Check, is ip blocked
  def check_blocked_ip
    @blocked_ip = BlockedIp.find_by_ip(request.remote_ip)

    unless @blocked_ip.blank?
      # Card is blocked
      flash[:error_card] = 'Ip is blocked'

      # Add transaction
      add_transaction(:i_account => $uid,
                      :i_cc => @credit_card.i_cc,
                      :type => "payment_refund",
                      :ip => request.remote_ip.to_s)
      false
    else
      true
    end
  end

  # Find account
  def find_account
    # Find a account
    @account = Account.find($uid)
    @credit_card = @account.creditcard
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end