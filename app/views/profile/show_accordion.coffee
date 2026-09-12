# the next lines are a hotfix for Firefox since it screws up the
# view
if window.matchMedia("screen and (max-width: 767px)")
  .matches || window.matchMedia("screen and (max-device-width: 767px)").matches
    document.getElementById('<%= @link %>').scrollIntoView()