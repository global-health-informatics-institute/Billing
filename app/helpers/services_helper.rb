module ServicesHelper
  def category_options(selected_category = [])
    options_array = [[]] + ServiceType.select(:service_type_id,:name).collect{|x| [x.name,x.service_type_id]}
    options_for_select(options_array, selected_category)
  end

end
