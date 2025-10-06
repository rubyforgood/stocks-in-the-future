# frozen_string_literal: true

module OrdersHelper
  # Renders a Buy button that opens the order form in a modal
  # Requires: shared/modal partial to be rendered on the page (included in application layout)
  # Options:
  #   disabled: true - renders a disabled button instead of a link
  def buy_button(stock_id, options = {})
    css_class = options.delete(:class)
    disabled = options.delete(:disabled)

    if disabled
      content_tag(:button, disabled: true,
                           class: "tw-btn-buy disabled:opacity-50 disabled:pointer-events-none #{css_class}".strip) do
        safe_join([content_tag(:i, "", class: "fa-solid fa-angle-up"), " Buy"])
      end
    else
      link_to new_order_path(stock_id: stock_id, transaction_type: :buy),
              **options, class: "tw-btn-buy #{css_class}".strip, data: { turbo_frame: "modal_frame" } do
        safe_join([content_tag(:i, "", class: "fa-solid fa-angle-up"), " Buy"])
      end
    end
  end

  # Renders a Sell button that opens the order form in a modal
  # Requires: shared/modal partial to be rendered on the page (included in application layout)
  # Options:
  #   disabled: true - renders a disabled button instead of a link
  def sell_button(stock_id, options = {})
    css_class = options.delete(:class)
    disabled = options.delete(:disabled)

    if disabled
      content_tag(:button, disabled: true,
                           class: "tw-btn-sell disabled:opacity-50 disabled:pointer-events-none #{css_class}".strip) do
        safe_join([content_tag(:i, "", class: "fa-solid fa-angle-down"), " Sell"])
      end
    else
      link_to new_order_path(stock_id: stock_id, transaction_type: :sell),
              **options, class: "tw-btn-sell #{css_class}".strip, data: { turbo_frame: "modal_frame" } do
        safe_join([content_tag(:i, "", class: "fa-solid fa-angle-down"), " Sell"])
      end
    end
  end

  # Renders a Trade button that opens the order form in a modal where you can select buy/sell
  # Requires: shared/modal partial to be rendered on the page (included in application layout)
  def trade_button(_stock_id, _options = {})
    # TODO: do we need unified trade button?
    nil
  end
end
