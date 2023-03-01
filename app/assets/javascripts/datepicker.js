"use strict"

var datePicker = ({

    cellMap: {
        0: {
            row: 2,
            col: 5
        },
        1: {
            row: 2,
            col: 6
        },
        2: {
            row: 3,
            col: 5
        },
        3: {
            row: 3,
            col: 6
        },
        4: {
            row: 4,
            col: 5
        },
        5: {
            row: 4,
            col: 6
        },
        6: {
            row: 5,
            col: 5
        },
        7: {
            row: 5,
            col: 6
        },
        8: {
            row: 6,
            col: 5
        },
        9: {
            row: 6,
            col: 6
        },
        10: {
            row: 7,
            col: 5
        },
        11: {
            row: 7,
            col: 6
        }
    },

    months: {
        "January": 0,
        "February": 1,
        "March": 2,
        "April": 3,
        "May": 4,
        "June": 5,
        "July": 6,
        "August": 7,
        "September": 8,
        "October": 9,
        "November": 10,
        "December": 11
    },

    ruleGroups: {
        "text1-1": {
            1: [2]
        }
    },

    currentDate: null,

    $: function (id) {

        return document.getElementById(id);

    },

    padZeros: function (number, positions) {
        var zeros = parseInt(positions) - String(number).length;
        var padded = "";

        for (var i = 0; i < zeros; i++) {
            padded += "0";
        }

        padded += String(number);

        return padded;
    },

    sheet: function (parent) {
        // Create the <style> tag
        var style = document.createElement("style");

        style.appendChild(document.createTextNode(""));

        // Add the <style> element to the page
        parent.appendChild(style);

        return style.sheet;
    },

    addCSSRule: function (sheet, selector, rules, index) {

        if ("insertRule" in sheet) {
            sheet.insertRule(selector + "{" + rules + "}", index);
        }
        else if ("addRule" in sheet) {
            sheet.addRule(selector, rules, index);
        }

    },

    leapYear: function (year) {

        var yr = parseInt(year);

        var result = ((yr % 4 == 0 && yr % 100 != 0) || yr % 400 == 0);

        return result;

    },

    checkDate: function (pos) {

        var year =
            (parseInt((datePicker.$("text1-0").value.trim().length > 0 ? datePicker.$("text1-0").value : 0)) * 1000) +
            (parseInt((datePicker.$("text1-1").value.trim().length > 0 ? datePicker.$("text1-1").value : 0)) * 100) +
            (parseInt((datePicker.$("text1-2").value.trim().length > 0 ? datePicker.$("text1-2").value : 0)) * 10) +
            (parseInt((datePicker.$("text1-3").value.trim().length > 0 ? datePicker.$("text1-3").value : 0)));

        var month =
            (datePicker.$("text1-5").value.trim().length > 0 ? datePicker.months[datePicker.$("text1-5").value.trim()] : -1);

        var date =
            (parseInt((datePicker.$("text1-7").value.trim().length > 0 ? datePicker.$("text1-7").value : 0)) * 10) +
            (parseInt((datePicker.$("text1-8").value.trim().length > 0 ? datePicker.$("text1-8").value : 0)));

        datePicker.currentDate = year + "-" + (datePicker.padZeros((month + 1), 2)) + "-" + (datePicker.padZeros(date, 2));

        var target = ([5, 6].indexOf(pos) >= 0 ? 5 : ([8, 9].indexOf(pos) >= 0 ? (pos - 1) : pos));

        var ruleGroups = {
            "text1-1": {
                1: [2, 4, 11]
            },
            "text1-2": {
                2: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            },
            "text1-3": {
                3: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            },
            "text1-5": {
                5: [2, 3, 4, 5, 6, 7],
                6: [2, 3, 4, 5, 6, 7]
            },
            "text1-7": {
                8: [2, 3, 4, 5]
            },
            "text1-8": {
                9: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            }
        };

        var texts = ["text1-1", "text1-2", "text1-3", "text1-5", "text1-7", "text1-8"];

        if (target > 2) {

            if (datePicker.$("btn12-2")) {

                datePicker.$("btn12-2").className = "datePickerBlue datePickerButton";

            }

        } else {

            if (datePicker.$("btn12-2")) {

                datePicker.$("btn12-2").className = "datePickerGray datePickerButton";

            }

        }

        if (target > 4) {

            if (datePicker.$("btn12-4")) {

                datePicker.$("btn12-4").className = "datePickerBlue datePickerButton";

            }

        } else {

            if (datePicker.$("btn12-4")) {

                datePicker.$("btn12-4").className = "datePickerGray datePickerButton";

            }

        }

        if (datePicker.$("text1-" + target).value.trim().length <= 0) {

            switch (target) {

                case 2:
                    texts = ["text1-3", "text1-5", "text1-7", "text1-8"];
                    break;

                case 3:
                    texts = ["text1-5", "text1-7", "text1-8"];
                    break;

                case 5:
                    texts = ["text1-7", "text1-8"];
                    break;

                case 7:
                    texts = ["text1-8"];
                    break;

                case 8:
                    texts = [];
                    break;

                default:
                    texts = ["text1-1", "text1-2", "text1-3", "text1-5", "text1-7", "text1-8"];
                    break;

            }

            for (var i = 0; i < texts.length; i++) {

                var key = texts[i];

                var cols = Object.keys(ruleGroups[key]);

                for (var c = 0; c < cols.length; c++) {

                    for (var r = 0; r < ruleGroups[key][cols[c]].length; r++) {

                        var row = ruleGroups[key][cols[c]][r];

                        if (datePicker.$("btn" + row + "-" + cols[c])) {

                            datePicker.$("btn" + row + "-" + cols[c]).className = "datePickerGray datePickerButton";

                        }

                    }

                }

            }

        } else if (datePicker.$("text1-" + target).value.trim().length > 0) {

            switch (target) {

                case 0:
                    texts = ["text1-1", "text1-2", "text1-3", "text1-5", "text1-7", "text1-8"];
                    break;

                case 1:
                    texts = ["text1-2", "text1-3", "text1-5", "text1-7", "text1-8"];
                    break;

                case 2:
                    texts = ["text1-3", "text1-5", "text1-7", "text1-8"];
                    break;

                case 3:
                    texts = ["text1-5", "text1-7", "text1-8"];
                    break;

                case 5:
                    texts = ["text1-7", "text1-8"];
                    break;

                case 7:
                    texts = ["text1-8"];
                    break;

                case 8:
                    texts = [];
                    break;

            }

            for (var i = 0; i < texts.length; i++) {

                var key = texts[i];

                if (datePicker.$(texts[i])) {

                    datePicker.$(texts[i]).value = "";

                }

                var cols = Object.keys(ruleGroups[key]);

                for (var c = 0; c < cols.length; c++) {

                    for (var r = 0; r < ruleGroups[key][cols[c]].length; r++) {

                        var row = ruleGroups[key][cols[c]][r];

                        if (datePicker.$("btn" + row + "-" + cols[c])) {

                            datePicker.$("btn" + row + "-" + cols[c]).className = "datePickerGray datePickerButton";

                        }

                    }

                }

            }

            switch (target) {

                case 0:
                    texts = ["text1-1"];
                    break;

                case 1:
                    texts = ["text1-2"];
                    break;

                case 2:
                    texts = ["text1-3"];
                    break;

                case 3:
                    texts = ["text1-5"];
                    break;

                case 5:
                    texts = ["text1-7"];
                    break;

                case 7:
                    texts = ["text1-8"];
                    break;

                case 8:
                    texts = [];
                    break;

            }

            if (target == 0 && year < 2000 && year > 0) {

                ruleGroups["text1-1"][1] = [11];

            } else if (target == 0 && year >= 2000) {

                ruleGroups["text1-1"][1] = [2];

            }

            if (date == 0 && target == 7) {

                ruleGroups["text1-8"][9].splice(ruleGroups["text1-8"][9].indexOf(2), 1);

            }

            var maxYr = (this.maxDate != undefined ? (!isNaN((new Date(this.maxDate)).getFullYear()) ?
                (new Date(this.maxDate)) : (new Date())) : (new Date())).getFullYear();

            var maxMonth = (this.maxDate != undefined ? (!isNaN((new Date(this.maxDate)).getMonth()) ?
                (new Date(this.maxDate)) : (new Date())) : (new Date())).getMonth();

            var maxDate = (this.maxDate != undefined ? (!isNaN((new Date(this.maxDate)).getDate()) ?
                (new Date(this.maxDate)) : (new Date())) : (new Date())).getDate();

            var monthMaxes = {
                0: 31,
                1: (datePicker.leapYear(year) ? 29 : 28),
                2: 31,
                3: 30,
                4: 31,
                5: 30,
                6: 31,
                7: 31,
                8: 30,
                9: 31,
                10: 30,
                11: 31
            };

            if (target == 1 && year >= 2000) {

                var max = Math.floor((maxYr % 100) / 10);

                var arr = [];

                for (var i = 0; i <= max; i++) {

                    arr.push(i + 2);

                }

                ruleGroups["text1-2"][2] = arr;

            } else if (target == 2 && year >= 2000) {

                if (Math.floor((year % 100) / 10) >= Math.floor((maxYr % 100) / 10)) {

                    var max = Math.floor((maxYr % 1000) % 10);

                    var arr = [];

                    for (var i = 0; i <= max; i++) {

                        arr.push(i + 2);

                    }

                    ruleGroups["text1-3"][3] = arr;

                }

            } else if (target == 3 && year == maxYr) {

                var max = maxMonth;

                var arr1 = [];
                var arr2 = [];

                var j = 0;
                for (var i = 0; i <= max; i++) {

                    if (i % 2 == 0) {

                        arr1.push(j + 2);

                    } else {

                        arr2.push(j + 2);

                        j++;

                    }

                }

                ruleGroups["text1-5"][5] = arr1;

                ruleGroups["text1-5"][6] = arr2;

            } else if (target == 5) {

                var max = (month == maxMonth && maxYr == year ? ((Math.floor(date / 10)) > (month * 10) ? ((Math.floor(maxDate / 10)) - 1) :
                    (Math.floor(maxDate / 10))) : (month == 1 ? 2 : 3));

                var arr = [];

                for (var i = 0; i <= max; i++) {

                    arr.push(i + 2);

                }

                ruleGroups["text1-7"][8] = arr;

            } else if (target == 7) {

                var max = 0;

                if ((Math.floor(date / 10) == Math.floor(maxDate / 10)) && (date % 10) > (maxDate % 10) &&
                    year == maxYr && month == maxMonth) {

                    max = (maxDate % 10);

                } else if ((Math.floor(date / 10) == Math.floor(maxDate / 10)) && (date % 10) <= (maxDate % 10) &&
                    year == maxYr && month == maxMonth) {

                    max = (maxDate % 10);

                } else if ((Math.floor(date / 10) < Math.floor(monthMaxes[month] / 10)) && (date % 10) < (monthMaxes[month] % 10) &&
                    year == maxYr && month == maxMonth) {

                    max = 11;

                } else if ((Math.floor(date / 10) == Math.floor(monthMaxes[month] / 10)) && date <= monthMaxes[month]) {

                    max = (monthMaxes[month] % 10);

                } else if ((Math.floor(date / 10) == Math.floor(monthMaxes[month] / 10)) && date > monthMaxes[month]) {

                    max = (monthMaxes[month] % 10);

                } else {

                    max = 11;

                }

                var arr = [];

                for (var i = 0; i <= max; i++) {

                    arr.push(i + 2);

                }

                if (date == 0) {

                    arr.splice(arr.indexOf(2), 1);

                }

                ruleGroups["text1-8"][9] = arr;

            }

            for (var i = 0; i < texts.length; i++) {

                var key = texts[i];

                var cols = Object.keys(ruleGroups[key]);

                for (var c = 0; c < cols.length; c++) {

                    for (var r = 0; r < ruleGroups[key][cols[c]].length; r++) {

                        var row = ruleGroups[key][cols[c]][r];

                        if (datePicker.$("btn" + row + "-" + cols[c])) {

                            datePicker.$("btn" + row + "-" + cols[c]).className = "datePickerBlue datePickerButton";

                        }

                    }

                }

            }

        }

    },

    loadDate: function (date) {

        var __date = new Date(date);

        if (isNaN(__date))
            return;

        var year = __date.getFullYear();

        var yr = String(year).split("");

        for (var i = 0; i < yr.length; i++) {

            var digit = parseInt(yr[i]);

            if (datePicker.$("btn" + (2 + digit) + "-" + i)) {

                datePicker.$("btn" + (2 + digit) + "-" + i).click();

            }

        }

        var month = __date.getMonth();

        var dat = __date.getDate();

        if (datePicker.estimate && parseInt(datePicker.estimate.value.trim()) == 1 && month == 6 && dat == 10) {

            if (datePicker.$("text1-5")) {

                datePicker.$("text1-5").value = "?";

            }

            if (datePicker.$("text1-7")) {

                datePicker.$("text1-7").value = "?";

            }

            if (datePicker.$("text1-8")) {

                datePicker.$("text1-8").value = "?";

            }

            return;

        } else {

            var cell = datePicker.cellMap[month];

            if (datePicker.$("btn" + cell.row + "-" + cell.col)) {

                datePicker.$("btn" + cell.row + "-" + cell.col).click();

            }

        }

        if (datePicker.estimate && parseInt(datePicker.estimate.value.trim()) == 1 && dat == 5) {

            if (datePicker.$("text1-7")) {

                datePicker.$("text1-7").value = "?";

            }

            if (datePicker.$("text1-8")) {

                datePicker.$("text1-8").value = "?";

            }

        } else {

            var row = (dat > 9 ? Math.floor(dat / 10) : 0) + 2;

            var cell = Math.floor(dat % 10) + 2;

            if (datePicker.$("btn" + row + "-8")) {

                datePicker.$("btn" + row + "-8").click();

            }

            if (datePicker.$("btn" + cell + "-9")) {

                datePicker.$("btn" + cell + "-9").click();

            }

        }

    },

    buildAgeEstimator: function () {

        if (datePicker.$("date.picker.div")) {

            datePicker.$("date.picker.div").innerHTML = "";

        }

        var table = document.createElement("table");
        table.style.margin = "auto";
        table.style.marginTop = "45px";
        table.border = 0;

        datePicker.$("date.picker.div").appendChild(table);

        var grid = [
            [
                [(datePicker.seedDate.getAttribute("estimate_label") ? datePicker.seedDate.getAttribute("estimate_label") :
                    "Age Estimate"), 3, "font-weight: normal; font-size: 30px; padding: 8px;"]
            ],
            [
                [undefined, 3, "width: 210px; height: 30px; text-align: center; font-size: 24px; min-height: 50px;", undefined, undefined, true]
            ],
            [
                ["7", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["8", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["9", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["4", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["5", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["6", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["3", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["0", 1, undefined, 'datePickerGray datePickerButton', true],
                ["del", 2, "width: 140px;", 'datePickerGray datePickerButton', true]
            ]
        ];

        for (var i = 0; i < grid.length; i++) {

            var tr = document.createElement("tr");

            table.appendChild(tr);

            for (var j = 0; j < grid[i].length; j++) {

                var td = document.createElement("td");
                td.align = "center";

                tr.appendChild(td);

                td.id = i + "-" + j;
                td.colSpan = grid[i][j][1];

                if (grid[i][j][5]) {

                    var input = document.createElement("input");
                    input.type = "text";
                    input.id = "text" + i + "-" + j;

                    if (grid[i][j][2]) {

                        input.setAttribute("style", grid[i][j][2]);

                    }

                    td.appendChild(input);

                } else if (grid[i][j][4] != undefined) {

                    var btn = document.createElement("button");
                    btn.className = grid[i][j][3];
                    btn.id = "btn" + i + "-" + j;
                    btn.innerHTML = grid[i][j][0];
                    btn.style.minWidth = "60px";
                    btn.style.minHeight = "45px !important";

                    if (grid[i][j][2]) {

                        btn.setAttribute("style", grid[i][j][2]);

                    }

                    td.appendChild(btn);

                    btn.onclick = function () {

                        if (this.className.match(/datePickerGray/))
                            return;

                        if (this.innerHTML.trim() == "del") {

                            if (datePicker.$("text1-0")) {

                                datePicker.$("text1-0").value = datePicker.$("text1-0").value.trim().substring(0,
                                        datePicker.$("text1-0").value.trim().length - 1);

                            }

                        } else {

                            if (datePicker.$("text1-0")) {

                                datePicker.$("text1-0").value += this.innerHTML.trim();

                            }

                        }

                        if (datePicker.$("text1-0") && datePicker.$("text1-0").value.trim().length <= 0) {

                            if (datePicker.$("btn5-0")) {

                                datePicker.$("btn5-0").className = "datePickerGray datePickerButton";

                            }

                            if (datePicker.$("btn5-1")) {

                                datePicker.$("btn5-1").className = "datePickerGray datePickerButton";

                            }

                        } else {

                            if (datePicker.$("btn5-0")) {

                                datePicker.$("btn5-0").className = "datePickerBlue datePickerButton";

                            }

                            if (datePicker.$("btn5-1")) {

                                datePicker.$("btn5-1").className = "datePickerBlue datePickerButton";

                            }

                            var date = ((new Date()).getFullYear() - parseInt(datePicker.$("text1-0").value.trim())) +
                                "-07-15";

                            if (datePicker.seedDate) {

                                datePicker.seedDate.value = date;

                            }

                            if (datePicker.estimate) {

                                datePicker.estimate.value = 1;

                            }

                        }

                    }

                } else if (grid[i][j][0]) {

                    td.innerHTML = grid[i][j][0];

                    if (grid[i][j][2]) {

                        td.setAttribute("style", grid[i][j][2]);

                    }

                }

            }
        }

        var label = document.createElement("div");
        label.id = "pat.label";
        label.style.position = "absolute";
        label.style.top = "0px";
        label.style.left = "0px";
        label.style.fontSize = "28px";
        label.style.width = "100%";
        label.innerHTML = (this.seedDate ? this.seedDate.getAttribute("helpText") : "");
        label.style.borderBottom = "2px dotted black";
        label.style.padding = "5px";
        label.style.color = "black";

        if (document.getElementById("date.picker.div")) {

            document.getElementById("date.picker.div").appendChild(label);

        }

    },

    buildControl: function () {

        if (this.target) {

            this.target.innerHTML = "";

        }

        var style = this.sheet(this.target);
        this.addCSSRule(style, ".headTab", "width: 100%");
        this.addCSSRule(style, ".headTab", "box-shadow: 5px 2px 5px 0px rgba(0,0,0,0.75)");
        this.addCSSRule(style, ".headTab", "overflow: hidden");
        this.addCSSRule(style, ".headTab", "height: 120px");
        this.addCSSRule(style, ".headTab", "border: 1px solid #004586");
        this.addCSSRule(style, ".datePickerBlueText", "color: #3c60b1");

        this.addCSSRule(style, ".datePickerButton", "font-size: 22px !important");
        this.addCSSRule(style, ".datePickerButton", "padding: 5px");
        this.addCSSRule(style, ".datePickerButton", "min-width: 60px");
        this.addCSSRule(style, ".datePickerButton", "cursor: pointer");
        this.addCSSRule(style, ".datePickerButton", "min-height: 45px");
        this.addCSSRule(style, ".datePickerButton", "border-radius: 5px !important");
        this.addCSSRule(style, ".datePickerButton", "margin: 3px");

        this.addCSSRule(style, ".datePickerButton:active", "background-color: #ffc579 !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: -webkit-gradient(linear, left top, left bottom, from(#ffc579), to(#fb9d23)) !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: -webkit-linear-gradient(top, #ffc579, #fb9d23) !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: -moz-linear-gradient(top, #ffc579, #fb9d23) !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: -ms-linear-gradient(top, #ffc579, #fb9d23) !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: -o-linear-gradient(top, #ffc579, #fb9d23) !important");
        this.addCSSRule(style, ".datePickerButton:active", "background-image: linear-gradient(to bottom, #ffc579, #fb9d23)");
        this.addCSSRule(style, ".datePickerButton:active", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#ffc579, endColorstr=#fb9d23) !important");

        this.addCSSRule(style, ".datePickerBlue", "border: 1px solid #7eb9d0");
        this.addCSSRule(style, ".datePickerBlue", "-webkit-border-radius: 3px");
        this.addCSSRule(style, ".datePickerBlue", "-moz-border-radius: 3px");
        this.addCSSRule(style, ".datePickerBlue", "border-radius: 3px");
        this.addCSSRule(style, ".datePickerBlue", "font-size: 28px");
        this.addCSSRule(style, ".datePickerBlue", "font-family: arial, helvetica, sans-serif");
        this.addCSSRule(style, ".datePickerBlue", "padding: 10px 10px 10px 10px");
        this.addCSSRule(style, ".datePickerBlue", "text-decoration: none");
        this.addCSSRule(style, ".datePickerBlue", "display: inline-block");
        this.addCSSRule(style, ".datePickerBlue", "text-shadow: -1px -1px 0 rgba(0, 0, 0, 0.3)");
        this.addCSSRule(style, ".datePickerBlue", "font-weight: bold");
        this.addCSSRule(style, ".datePickerBlue", "color: #FFFFFF");
        this.addCSSRule(style, ".datePickerBlue", "background-color: #a7cfdf");
        this.addCSSRule(style, ".datePickerBlue", "background-image: -webkit-gradient(linear, left top, left bottom, from(#a7cfdf), to(#23538a))");
        this.addCSSRule(style, ".datePickerBlue", "background-image: -webkit-linear-gradient(top, #a7cfdf, #23538a)");
        this.addCSSRule(style, ".datePickerBlue", "background-image: -moz-linear-gradient(top, #a7cfdf, #23538a)");
        this.addCSSRule(style, ".datePickerBlue", "background-image: -ms-linear-gradient(top, #a7cfdf, #23538a)");
        this.addCSSRule(style, ".datePickerBlue", "background-image: -o-linear-gradient(top, #a7cfdf, #23538a)");
        this.addCSSRule(style, ".datePickerBlue", "background-image: linear-gradient(to bottom, #a7cfdf, #23538a)");
        this.addCSSRule(style, ".datePickerBlue", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#a7cfdf, endColorstr=#23538a)");

        this.addCSSRule(style, ".datePickerBlue:hover", "border: 1px solid #5ca6c4");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-color: #82bbd1");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: -webkit-gradient(linear, left top, left bottom, from(#82bbd1), to(#193b61))");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: -webkit-linear-gradient(top, #82bbd1, #193b61)");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: -moz-linear-gradient(top, #82bbd1, #193b61)");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: -ms-linear-gradient(top, #82bbd1, #193b61)");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: -o-linear-gradient(top, #82bbd1, #193b61)");
        this.addCSSRule(style, ".datePickerBlue:hover", "background-image: linear-gradient(to bottom, #82bbd1, #193b61)");
        this.addCSSRule(style, ".datePickerBlue:hover", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#82bbd1, endColorstr=#193b61)");

        this.addCSSRule(style, ".datePickerGreen", "border: 1px solid #34740e");
        this.addCSSRule(style, ".datePickerGreen", "-webkit-border-radius: 3px");
        this.addCSSRule(style, ".datePickerGreen", "-moz-border-radius: 3px");
        this.addCSSRule(style, ".datePickerGreen", "border-radius: 3px");
        this.addCSSRule(style, ".datePickerGreen", "font-size: 28px");
        this.addCSSRule(style, ".datePickerGreen", "font-family: arial, helvetica, sans-serif");
        this.addCSSRule(style, ".datePickerGreen", "padding: 10px 10px 10px 10px");
        this.addCSSRule(style, ".datePickerGreen", "text-decoration: none");
        this.addCSSRule(style, ".datePickerGreen", "display: inline-block");
        this.addCSSRule(style, ".datePickerGreen", "text-shadow: -1px -1px 0 rgba(0, 0, 0, 0.3)");
        this.addCSSRule(style, ".datePickerGreen", "font-weight: bold");
        this.addCSSRule(style, ".datePickerGreen", "color: #FFFFFF");
        this.addCSSRule(style, ".datePickerGreen", "background-color: #4ba614");
        this.addCSSRule(style, ".datePickerGreen", "background-image: -webkit-gradient(linear, left top, left bottom, from(#4ba614), to(#008c00))");
        this.addCSSRule(style, ".datePickerGreen", "background-image: -webkit-linear-gradient(top, #4ba614, #008c00)");
        this.addCSSRule(style, ".datePickerGreen", "background-image: -moz-linear-gradient(top, #4ba614, #008c00)");
        this.addCSSRule(style, ".datePickerGreen", "background-image: -ms-linear-gradient(top, #4ba614, #008c00)");
        this.addCSSRule(style, ".datePickerGreen", "background-image: -o-linear-gradient(top, #4ba614, #008c00)");
        this.addCSSRule(style, ".datePickerGreen", "background-image: linear-gradient(to bottom, #4ba614, #008c00)");
        this.addCSSRule(style, ".datePickerGreen", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#4ba614, endColorstr=#008c00)");

        this.addCSSRule(style, ".datePickerGreen:hover", "border: 1px solid #224b09");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-color: #36780f");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: -webkit-gradient(linear, left top, left bottom, from(#36780f), to(#005900))");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: -webkit-linear-gradient(top, #36780f, #005900)");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: -moz-linear-gradient(top, #36780f, #005900)");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: -ms-linear-gradient(top, #36780f, #005900)");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: -o-linear-gradient(top, #36780f, #005900)");
        this.addCSSRule(style, ".datePickerGreen:hover", "background-image: linear-gradient(to bottom, #36780f, #005900)");
        this.addCSSRule(style, ".datePickerGreen:hover", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#36780f, endColorstr=#005900)");

        this.addCSSRule(style, ".datePickerRed", "border: 1px solid #72021c");
        this.addCSSRule(style, ".datePickerRed", "-webkit-border-radius: 3px");
        this.addCSSRule(style, ".datePickerRed", "-moz-border-radius: 3px");
        this.addCSSRule(style, ".datePickerRed", "border-radius: 3px");
        this.addCSSRule(style, ".datePickerRed", "font-size: 28px");
        this.addCSSRule(style, ".datePickerRed", "font-family: arial, helvetica, sans-serif");
        this.addCSSRule(style, ".datePickerRed", "padding: 10px 10px 10px 10px");
        this.addCSSRule(style, ".datePickerRed", "text-decoration: none");
        this.addCSSRule(style, ".datePickerRed", "display: inline-block");
        this.addCSSRule(style, ".datePickerRed", "text-shadow: -1px -1px 0 rgba(0, 0, 0, 0.3)");
        this.addCSSRule(style, ".datePickerRed", "font-weight: bold");
        this.addCSSRule(style, ".datePickerRed", "color: #FFFFFF");
        this.addCSSRule(style, ".datePickerRed", "background-color: #a90329");
        this.addCSSRule(style, ".datePickerRed", "background-image: -webkit-gradient(linear, left top, left bottom, from(#a90329), to(#6d0019))");
        this.addCSSRule(style, ".datePickerRed", "background-image: -webkit-linear-gradient(top, #a90329, #6d0019)");
        this.addCSSRule(style, ".datePickerRed", "background-image: -moz-linear-gradient(top, #a90329, #6d0019)");
        this.addCSSRule(style, ".datePickerRed", "background-image: -ms-linear-gradient(top, #a90329, #6d0019)");
        this.addCSSRule(style, ".datePickerRed", "background-image: -o-linear-gradient(top, #a90329, #6d0019)");
        this.addCSSRule(style, ".datePickerRed", "background-image: linear-gradient(to bottom, #a90329, #6d0019)");
        this.addCSSRule(style, ".datePickerRed", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#a90329, endColorstr=#6d0019)");

        this.addCSSRule(style, ".datePickerRed:hover", "border: 1px solid #450111");
        this.addCSSRule(style, ".datePickerRed:hover", "background-color: #77021d");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: -webkit-gradient(linear, left top, left bottom, from(#77021d), to(#3a000d))");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: -webkit-linear-gradient(top, #77021d, #3a000d)");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: -moz-linear-gradient(top, #77021d, #3a000d)");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: -ms-linear-gradient(top, #77021d, #3a000d)");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: -o-linear-gradient(top, #77021d, #3a000d)");
        this.addCSSRule(style, ".datePickerRed:hover", "background-image: linear-gradient(to bottom, #77021d, #3a000d)");
        this.addCSSRule(style, ".datePickerRed:hover", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#77021d, endColorstr=#3a000d)");

        // this.addCSSRule(style, ".datePickerGray", "display: none");
        this.addCSSRule(style, ".datePickerGray", "border: 0px solid #ddd");
        this.addCSSRule(style, ".datePickerGray", "-webkit-border-radius: 3px");
        this.addCSSRule(style, ".datePickerGray", "-moz-border-radius: 3px");
        this.addCSSRule(style, ".datePickerGray", "border-radius: 3px");
        this.addCSSRule(style, ".datePickerGray", "font-size: 28px");
        this.addCSSRule(style, ".datePickerGray", "font-family: arial, helvetica, sans-serif");
        this.addCSSRule(style, ".datePickerGray", "padding: 10px 10px 10px 10px");
        this.addCSSRule(style, ".datePickerGray", "text-decoration: none");
        this.addCSSRule(style, ".datePickerGray", "display: inline-block");
        this.addCSSRule(style, ".datePickerGray", "text-shadow: 0px 0px 0 rgba(0, 0, 0, 0.3)");
        this.addCSSRule(style, ".datePickerGray", "font-weight: normal");
        this.addCSSRule(style, ".datePickerGray", "color: #bbb");
        this.addCSSRule(style, ".datePickerGray", "background-color: #ddd");
        this.addCSSRule(style, ".datePickerGray", "background-image: -webkit-gradient(linear, left top, left bottom, from(#ddd), to(#ddd))");
        this.addCSSRule(style, ".datePickerGray", "background-image: -webkit-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray", "background-image: -moz-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray", "background-image: -ms-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray", "background-image: -o-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray", "background-image: linear-gradient(to bottom, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#ddd, endColorstr=#ddd)");

        this.addCSSRule(style, ".datePickerGray:hover", "border: 0px solid #ddd");
        this.addCSSRule(style, ".datePickerGray:hover", "background-color: #ddd");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: -webkit-gradient(linear, left top, left bottom, from(#ddd), to(#ddd))");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: -webkit-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: -moz-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: -ms-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: -o-linear-gradient(top, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:hover", "background-image: linear-gradient(to bottom, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:hover", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#ddd, endColorstr=#ddd)");

        this.addCSSRule(style, ".datePickerGray:active", "background-color: #ddd !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: -webkit-gradient(linear, left top, left bottom, from(#ddd), to(#ddd)) !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: -webkit-linear-gradient(top, #ddd, #ddd) !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: -moz-linear-gradient(top, #ddd, #ddd) !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: -ms-linear-gradient(top, #ddd, #ddd) !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: -o-linear-gradient(top, #ddd, #ddd) !important");
        this.addCSSRule(style, ".datePickerGray:active", "background-image: linear-gradient(to bottom, #ddd, #ddd)");
        this.addCSSRule(style, ".datePickerGray:active", "filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0, startColorstr=#ddd, endColorstr=#ddd) !important");

        var div = document.createElement("div");
        div.id = "date.picker.div";
        div.style.width = "100%";
        div.style.height = "100%";
        div.style.backgroundColor = "#fff";
        div.style.MozUserSelect = "none";
        div.style.font = "28px 'Nimbus Sans L', 'Arial Narrow', sans-serif";
        div.style.color = "#3e649d";

        if (this.target) {

            this.target.appendChild(div);

        }

        var table = document.createElement("table");
        table.border = 0;
        table.style.borderCollapse = "collapse";
        table.style.margin = "auto";
        table.style.marginTop = "35px";
        table.cellPadding = 0;

        div.appendChild(table);

        var grid = [
            [
                ["Year", 4, "font-weight: normal; font-size: 32px; display: none;"],
                ["&nbsp;", 1],
                ["Month", 2, "font-weight: normal; font-size: 32px; display: none;"],
                ["&nbsp;", 1],
                ["Date", 2, "font-weight: normal; font-size: 32px; display: none;"]
            ],
            [
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true],
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true],
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true],
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true],
                ["&nbsp;", 1],
                ["&nbsp;", 2, "width: 315px; height: 30px; text-align: center; font-size: 24px; min-width: 330px; min-height: 50px;", undefined, undefined, true],
                ["&nbsp;", 1],
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true],
                ["&nbsp;", 1, "width: 50px; height: 30px; text-align: center; font-size: 24px; min-width: 65px !important; min-height: 50px !important;", undefined, undefined, true]
            ],
            [
                ["0", 1, undefined, 'datePickerGray datePickerButton', true],
                ["0", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["0", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["0", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["January", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["February", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["0", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["0", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["1", 1, undefined, 'datePickerGray datePickerButton', true],
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["March", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["April", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["1", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["May", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["June", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["2", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["3", 1, undefined, 'datePickerGray datePickerButton', true],
                ["3", 1, undefined, 'datePickerGray datePickerButton', true],
                ["3", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["3", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["July", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["August", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["3", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["3", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["4", 1, undefined, 'datePickerGray datePickerButton', true],
                ["4", 1, undefined, 'datePickerGray datePickerButton', true],
                ["4", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["4", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["September", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["October", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["4", 1, undefined, 'datePickerGray datePickerButton', true],
                ["4", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["5", 1, undefined, 'datePickerGray datePickerButton', true],
                ["5", 1, undefined, 'datePickerGray datePickerButton', true],
                ["5", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["5", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["November", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["December", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["5", 1, undefined, 'datePickerGray datePickerButton', true],
                ["5", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["6", 1, undefined, 'datePickerGray datePickerButton', true],
                ["6", 1, undefined, 'datePickerGray datePickerButton', true],
                ["6", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["6", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1],
                ["6", 1, undefined, 'datePickerGray datePickerButton', true],
                ["6", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["7", 1, undefined, 'datePickerGray datePickerButton', true],
                ["7", 1, undefined, 'datePickerGray datePickerButton', true],
                ["7", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["7", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1],
                ["7", 1, undefined, 'datePickerGray datePickerButton', true],
                ["7", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["8", 1, undefined, 'datePickerGray datePickerButton', true],
                ["8", 1, undefined, 'datePickerGray datePickerButton', true],
                ["8", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["8", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1],
                ["8", 1, undefined, 'datePickerGray datePickerButton', true],
                ["8", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["9", 1, undefined, 'datePickerGray datePickerButton', true],
                ["9", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["9", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["9", 1, undefined, 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1, undefined, 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1],
                ["9", 1, undefined, 'datePickerGray datePickerButton', true],
                ["9", 1, undefined, 'datePickerBlue datePickerButton', true]
            ],
            [
                ["Unknown", 4, "width: 200px; height: 30px; text-align: center; font-size: 24px; margin: auto;", 'datePickerBlue datePickerButton', true],
                ["&nbsp;", 1],
                ["Unknown", 2, "width: 200px; height: 30px; text-align: center; font-size: 24px; margin: auto;", 'datePickerGray datePickerButton', true],
                ["&nbsp;", 1],
                ["Unknown", 2, "width: 200px; height: 30px; text-align: center; font-size: 24px; margin: auto;", 'datePickerGray datePickerButton', true]
            ]
        ]

        for (var i = 0; i < grid.length; i++) {

            var tr = document.createElement("tr");

            table.appendChild(tr);

            for (var j = 0; j < grid[i].length; j++) {

                var td = document.createElement("td");
                td.id = i + "-" + j;
                td.colSpan = grid[i][j][1];

                if (i == 12) {

                    td.align = "center";

                }

                if (grid[i][j][4] != undefined) {

                    var btn = document.createElement("button");
                    btn.className = grid[i][j][3];
                    btn.id = "btn" + i + "-" + j;
                    btn.innerHTML = grid[i][j][0];


                    if (i == 12) {

                        btn.style.minWidth = "120px";
                        btn.style.minHeight = "45px !important";

                    } else if (grid[i][j][0].trim().length > 1) {

                        btn.style.minWidth = "160px";
                        btn.style.minHeight = "45px !important";

                    } else {

                        btn.style.minWidth = "60px";
                        btn.style.minHeight = "45px !important";

                    }

                    btn.onclick = function () {

                        if (this.className.split(" ").indexOf("datePickerGray") >= 0)
                            return;

                        var col = parseInt(this.id.match(/(\d)$/)[1]);

                        var row = parseInt(this.id.match(/(\d+)\-\d$/)[1]);

                        if (row == 12) {

                            if (col == 2) {

                                if (datePicker.$("text1-3")) {

                                    var digit = parseInt(datePicker.$("text1-3").value);

                                    if (datePicker.$("btn" + (2 + digit) + "-" + 3)) {

                                        datePicker.$("btn" + (2 + digit) + "-" + 3).click();

                                    }

                                }

                                if (datePicker.$("text1-5")) {

                                    datePicker.$("text1-5").value = "?";

                                }

                                if (datePicker.$("text1-7")) {

                                    datePicker.$("text1-7").value = "?";

                                }

                                if (datePicker.$("text1-8")) {

                                    datePicker.$("text1-8").value = "?";

                                }

                                if (datePicker.estimate) {

                                    datePicker.estimate.value = 1;

                                }

                                if (datePicker.seedDate) {

                                    datePicker.seedDate.value = (datePicker.$("text1-0").value.trim() +
                                        datePicker.$("text1-1").value.trim() + datePicker.$("text1-2").value.trim() +
                                        datePicker.$("text1-3").value.trim()) + "-07-10";

                                }

                                if (datePicker.$("btn12-4")) {

                                    datePicker.$("btn12-4").className = "datePickerGray datePickerButton";

                                }

                            } else if (col == 4) {

                                if (datePicker.$("text1-5")) {

                                    var month =
                                        (datePicker.$("text1-5").value.trim().length > 0 ? datePicker.months[datePicker.$("text1-5").value.trim()] : -1);

                                    var cell = datePicker.cellMap[month];

                                    if (datePicker.$("btn" + cell.row + "-" + cell.col)) {

                                        datePicker.$("btn" + cell.row + "-" + cell.col).click();

                                    }


                                }

                                if (datePicker.$("text1-7")) {

                                    datePicker.$("text1-7").value = "?";

                                }

                                if (datePicker.$("text1-8")) {

                                    datePicker.$("text1-8").value = "?";

                                }

                                if (datePicker.estimate) {

                                    datePicker.estimate.value = 1;

                                }

                                if (datePicker.seedDate) {

                                    datePicker.seedDate.value = (datePicker.$("text1-0").value.trim() +
                                        datePicker.$("text1-1").value.trim() + datePicker.$("text1-2").value.trim() +
                                        datePicker.$("text1-3").value.trim()) + "-" + datePicker.padZeros(
                                        (parseInt(datePicker.months[datePicker.$("text1-5").value.trim()]) + 1), 2) + "-05";

                                }

                            } else if (col == 0) {

                                if (datePicker.$("text1-0")) {

                                    var digit = (Math.floor((new Date()).getFullYear() / 1000));

                                    if (datePicker.$("btn" + (2 + digit) + "-" + 0)) {

                                        datePicker.$("btn" + (2 + digit) + "-" + 0).click();

                                    }

                                }

                                if (datePicker.$("text1-0")) {

                                    datePicker.$("text1-0").value = "?";

                                }

                                if (datePicker.$("text1-1")) {

                                    datePicker.$("text1-1").value = "?";

                                }

                                if (datePicker.$("text1-2")) {

                                    datePicker.$("text1-2").value = "?";

                                }

                                if (datePicker.$("text1-3")) {

                                    datePicker.$("text1-3").value = "?";

                                }

                                if (datePicker.$("text1-5")) {

                                    datePicker.$("text1-5").value = "?";

                                }

                                if (datePicker.$("text1-7")) {

                                    datePicker.$("text1-7").value = "?";

                                }

                                if (datePicker.$("text1-8")) {

                                    datePicker.$("text1-8").value = "?";

                                }

                                if (datePicker.estimate) {

                                    datePicker.estimate.value = 1;

                                }

                                if (datePicker.$("text1-0").value.trim() == "?") {

                                    for (var r = 0; r < datePicker.ruleGroups["text1-1"][1].length; r++) {

                                        var row = datePicker.ruleGroups["text1-1"][1][r];

                                        if (datePicker.$("btn" + row + "-" + 1)) {

                                            datePicker.$("btn" + row + "-" + 1).className = "datePickerGray datePickerButton";

                                        }

                                    }

                                }

                                datePicker.buildAgeEstimator();

                            }

                        } else {

                            switch (col) {

                                case 0:
                                case 1:
                                case 2:
                                case 3:

                                    if (datePicker.$("text1-" + col)) {

                                        datePicker.$("text1-" + col).value = parseInt(this.innerHTML);

                                    }

                                    break;
                                case 5:
                                case 6:

                                    if (datePicker.$("text1-5")) {

                                        datePicker.$("text1-5").value = this.innerHTML.trim();

                                    }

                                    break;
                                case 8:
                                case 9:

                                    if (datePicker.$("text1-" + (col - 1))) {

                                        datePicker.$("text1-" + (col - 1)).value = parseInt(this.innerHTML);

                                    }

                                    if (datePicker.estimate) {

                                        datePicker.estimate.value = 0;

                                    }

                                    if (datePicker.seedDate) {

                                        var year =
                                            (parseInt((datePicker.$("text1-0").value.trim().length > 0 ? datePicker.$("text1-0").value : 0)) * 1000) +
                                            (parseInt((datePicker.$("text1-1").value.trim().length > 0 ? datePicker.$("text1-1").value : 0)) * 100) +
                                            (parseInt((datePicker.$("text1-2").value.trim().length > 0 ? datePicker.$("text1-2").value : 0)) * 10) +
                                            (parseInt((datePicker.$("text1-3").value.trim().length > 0 ? datePicker.$("text1-3").value : 0)));

                                        var month =
                                            (datePicker.$("text1-5").value.trim().length > 0 ? datePicker.months[datePicker.$("text1-5").value.trim()] : -1);

                                        var date =
                                            (parseInt((datePicker.$("text1-7").value.trim().length > 0 ? datePicker.$("text1-7").value : 0)) * 10) +
                                            (parseInt((datePicker.$("text1-8").value.trim().length > 0 ? datePicker.$("text1-8").value : 0)));

                                        datePicker.currentDate = year + "-" + (datePicker.padZeros((month + 1), 2)) + "-" + (datePicker.padZeros(date, 2));

                                        datePicker.seedDate.value = datePicker.currentDate;

                                    }

                                    break;

                            }

                            var pos = parseInt(this.id.match(/(\d)$/)[1]);

                            datePicker.checkDate(pos);

                        }

                    }

                    td.appendChild(btn);

                } else if (grid[i][j][5] != undefined) {

                    var text = document.createElement("input");
                    text.id = "text" + i + "-" + j;
                    text.value = "";
                    text.type = "text";
                    text.setAttribute("readonly", true);

                    if (grid[i][j][2] != undefined) {

                        text.setAttribute("style", grid[i][j][2]);

                    }

                    switch (j) {

                        case 0:
                        case 1:
                        case 2:
                        case 3:

                            text.setAttribute("placeholder", "Y");

                            break;
                        case 5:

                            text.setAttribute("placeholder", "MMMM");

                            break;
                        case 7:
                        case 8:

                            text.setAttribute("placeholder", "D");

                            break;

                    }

                    td.appendChild(text);

                } else if (grid[i][j][3] != undefined) {

                    td.innerHTML = grid[i][j][0];
                    td.setAttribute("class", grid[i][j][3]);

                } else if (grid[i][j][2] != undefined) {

                    td.innerHTML = grid[i][j][0];
                    td.setAttribute("style", grid[i][j][2] + "; text-align: center; min-height: 50px; min-width: 50px;");

                } else {

                    td.innerHTML = grid[i][j][0];
                    td.style.textAlign = "center";
                    td.style.minHeight = "60px";
                    td.style.minWidth = "50px";

                }

                tr.appendChild(td);

            }

        }

        this.checkDate(0);

        if (this.seedDate) {

            var __date = (new Date(this.seedDate.value.trim()));

            if (!isNaN(__date)) {

                datePicker.loadDate(__date);

            }

        }

        var label = document.createElement("div");
        label.id = "pat.label";
        label.style.position = "absolute";
        label.style.top = "0px";
        label.style.left = "0px";
        label.style.fontSize = "28px";
        label.style.width = "100%";
        label.innerHTML = (this.seedDate ? this.seedDate.getAttribute("helpText") : "");
        label.style.borderBottom = "2px dotted black";
        label.style.padding = "5px";
        label.style.color = "black";

        if (document.getElementById("date.picker.div")) {

            document.getElementById("date.picker.div").appendChild(label);

        }

    },

    targetValue: "",

    tmrInterval: null,

    init: function (target, seedDate, estimate, maxDate, minDate) {

        this.target = target;

        this.maxDate = maxDate;

        this.minDate = minDate;

        this.seedDate = seedDate;

        this.estimate = estimate;

        this.targetValue = this.seedDate.value;

        this.buildControl();

        if (!datePicker.seedDate.getAttribute("optional")) {

            var currentClass = datePicker.$("nextButton").className;

            datePicker.$("nextButton").className = currentClass.replace(/blue|green/i, "gray");

            datePicker.tmrInterval = setInterval(function () {

                if (datePicker.$("text1-0") && datePicker.$("text1-1") && datePicker.$("text1-2") && datePicker.$("text1-3") &&
                    datePicker.$("text1-5") && datePicker.$("text1-7") && datePicker.$("text1-8")) {

                    if (datePicker.$("text1-0").value.trim().length <= 0 || datePicker.$("text1-1").value.trim().length <= 0 ||
                        datePicker.$("text1-2").value.trim().length <= 0 || datePicker.$("text1-3").value.trim().length <= 0 ||
                        datePicker.$("text1-5").value.trim().length <= 0 || datePicker.$("text1-7").value.trim().length <= 0 ||
                        datePicker.$("text1-8").value.trim().length <= 0) {

                        if (datePicker.seedDate) {

                            datePicker.seedDate.value = "";

                        }

                    }

                } else {

                    clearInterval(datePicker.tmrInterval);

                    var currentClass = datePicker.$("nextButton").className;

                    datePicker.$("nextButton").className = currentClass.replace(/gray/i, "green");

                    return;

                }

                if (datePicker.seedDate.value.trim() != datePicker.targetValue.trim() && datePicker.seedDate.value.trim().length > 0) {

                    datePicker.targetValue = datePicker.seedDate.value.trim();

                    var testDate = isNaN((new Date(datePicker.seedDate.value.trim())).getFullYear());

                    if (!testDate && datePicker.seedDate.value.trim().match(/^\d{4}\-\d{2}-\d{2}/) && datePicker.$("nextButton")) {

                        var currentClass = datePicker.$("nextButton").className;

                        datePicker.$("nextButton").className = currentClass.replace(/gray/i, "green");

                    }

                } else if (datePicker.seedDate.value.trim().length <= 0) {

                    if (datePicker.$("nextButton")) {

                        var currentClass = datePicker.$("nextButton").className;

                        datePicker.$("nextButton").className = currentClass.replace(/blue|green/i, "gray");

                    }

                }

            }, 100);

        }

    }

})