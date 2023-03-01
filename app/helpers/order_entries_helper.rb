module OrderEntriesHelper
  def entry_options(category)
    return ServiceType.find_by_name(category).services.collect{|x| x.name}
  end
  def panel_options(category)
    return ServiceType.find_by_name(category).service_panels.collect{|x| x.name} + ["Others"]
  end
  def sig
    return [[]]+ [["Twice a day", "BID"], ["Every other day", "EOD"], ["Once daily", "OD"],
                  ["Three times a day", "TDS"], ["Every hour", "q.h"], ["Every two hours", "q.2.h"],
                  ["Every three hours", "q.3.h"], ["Every four hours", "q.4.h"], ["Four times a day", "q.d.s"]]

  end

end
