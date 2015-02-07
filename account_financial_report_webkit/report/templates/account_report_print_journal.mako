## -*- coding: utf-8 -*-
<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <style type="text/css">
            .overflow_ellipsis {
                text-overflow: ellipsis;
                overflow: hidden;
                white-space: nowrap;
            }
            ${css}
        </style>
    </head>
    <body>
        <%!
        def amount(text):
            return text.replace('-', '&#8209;')  # replace by a non-breaking hyphen (it will not word-wrap between hyphen and numbers)
        %>

        <%setLang(user.lang)%>

        <%
        dict_account_summary = {}
        dict_taxcode_summary = {}
        from openerp import tools
        %>


        <div class="act_as_table data_table">
            <div class="act_as_row labels">
                <div class="act_as_cell">${_('Chart of Account')}</div>
                <div class="act_as_cell">${_('Fiscal Year')}</div>
                <div class="act_as_cell">
                    %if filter_form(data) == 'filter_date':
                        ${_('Dates Filter')}
                    %else:
                        ${_('Periods Filter')}
                    %endif
                </div>
                <div class="act_as_cell">${_('Journal Filter')}</div>
                <div class="act_as_cell">${_('Target Moves')}</div>
            </div>
            <div class="act_as_row">
                <div class="act_as_cell">${ chart_account.name }</div>
                <div class="act_as_cell">${ fiscalyear.name if fiscalyear else '-' }</div>
                <div class="act_as_cell">
                    ${_('From:')}
                    %if filter_form(data) == 'filter_date':
                        ${formatLang(start_date, date=True) if start_date else u'' }
                    %else:
                        ${start_period.name if start_period else u''}
                    %endif
                    ${_('To:')}
                    %if filter_form(data) == 'filter_date':
                        ${ formatLang(stop_date, date=True) if stop_date else u'' }
                    %else:
                        ${stop_period.name if stop_period else u'' }
                    %endif
                </div>
                <div class="act_as_cell">
                    %if journals(data):
                        ${', '.join([journal.name for journal in journals(data)])}
                    %else:
                        ${_('All')}
                    %endif

                </div>
                <div class="act_as_cell">${ display_target_move(data) }</div>
            </div>
        </div>

        %for journal_period in objects:
        <%
        account_total_debit = 0.0
        account_total_credit = 0.0
        account_total_currency = 0.0
        %>

        <div class="account_title bg" style="width: 1080px; margin-top: 20px; font-size: 12px;">${journal_period.journal_id.name} - ${journal_period.period_id.name}</div>

        <!-- we use div with css instead of table for tabular data because div do not cut rows at half at page breaks -->
        <div class="act_as_table list_table" style="margin-top: 5px;">
            <div class="act_as_thead">
                <div class="act_as_row labels">
                    ## date
                    <div class="act_as_cell first_column">${_('Date')}</div>
                    ## move
                    <div class="act_as_cell">${_('Entry')}</div>
                    ## account code
                    <div class="act_as_cell">${_('Account')}</div>
                    ## partner
                    <div class="act_as_cell" style="width: 280px;">${_('Partner')}</div>
                    ## date
                    <div class="act_as_cell">${_('Due Date')}</div>
                    ## label
                    <div class="act_as_cell" style="width: 310px;">${_('Label')}</div>
                    ## debit
                    <div class="act_as_cell amount">${_('Debit')}</div>
                    ## credit
                    <div class="act_as_cell amount">${_('Credit')}</div>
                    %if amount_currency(data):
                        ## currency balance
                        <div class="act_as_cell amount sep_left">${_('Curr. Balance')}</div>
                        ## curency code
                        <div class="act_as_cell amount" style="text-align: right;">${_('Curr.')}</div>
                    %endif
                    ## vat
                    <div class="act_as_cell">${_('Vat')}</div>
                </div>
            </div>
            %for move in moves[journal_period.id]:
            <%
            new_move = True
            %>

                %for line in move.line_id:
                <div class="act_as_tbody">
                    <%
                    account_total_debit += line.debit or 0.0
                    account_total_credit += line.credit or 0.0
                    %>
                    %if line.account_id.id in dict_account_summary:
                        <%
                        dict_account_summary[line.account_id.id]['credit'] += line.credit or 0.0
                        dict_account_summary[line.account_id.id]['debit'] += line.debit or 0.0
                        %>
                    %else:
                        <%dict_account_summary[line.account_id.id] = {
                                                                    'name':tools.ustr(line.account_id.code) + ' - ' + tools.ustr(line.account_id.name),
                                                                    'credit' : line.credit or 0.0,
                                                                    'debit' : line.debit or 0.0,
                                                                    'parent_left': line.account_id.parent_left,
                                                                    }
                        %>
                    %endif
                    %if line.tax_code_id.id:
                        %if line.tax_code_id.id in dict_taxcode_summary:
                            <%
                            dict_taxcode_summary[line.tax_code_id.id]['amount'] += line.tax_amount or 0.0
                            %>
                        %else:
                            <%
                            dict_taxcode_summary[line.tax_code_id.id] = {
                                                                        'code':tools.ustr(line.tax_code_id.code),
                                                                        'name': tools.ustr(line.tax_code_id.name),
                                                                        'amount' : line.tax_amount or 0.0
                                                                        }
                            %>
                        %endif
                    %endif
                    <div class="act_as_row lines">
                        ## date
                        <div class="act_as_cell first_column">${formatLang(move.date, date=True) if new_move else ''}</div>
                        ## move
                        <div class="act_as_cell">${move.name if new_move else ''}</div>
                        ## account code
                        <div class="act_as_cell">${line.account_id.code}</div>
                        ## partner
                        <div class="act_as_cell overflow_ellipsis" style="width: 280px;">${line.partner_id.name if new_move else line.account_id.name}</div>
                        ## date
                        <div class="act_as_cell">${formatLang(line.date_maturity or '', date=True)}</div>
                        ## label
                        <div class="act_as_cell overflow_ellipsis" style="width: 310px;">${line.name}</div>
                        ## debit
                        <div class="act_as_cell amount">${formatLang(line.debit) if line.debit else ''}</div>
                        ## credit
                        <div class="act_as_cell amount">${formatLang(line.credit) if line.credit else ''}</div>
                        %if amount_currency(data):
                            ## currency balance
                            <div class="act_as_cell amount sep_left">${formatLang(line.amount_currency) if line.amount_currency else ''}</div>
                            ## curency code
                            <div class="act_as_cell amount" style="text-align: right;">${line.currency_id.symbol or ''}</div>
                        %endif
                        ## vat code
                        <div class="act_as_cell">${line.tax_code_id.code or ''}</div>

                    </div>
                    <%
                    new_move = False
                    %>
                </div>
                %endfor
            %endfor
            <div class="act_as_row lines labels">
                ## date
                <div class="act_as_cell first_column"></div>
                ## move
                <div class="act_as_cell"></div>
                ## account code
                <div class="act_as_cell"></div>
                ## date
                <div class="act_as_cell"></div>
                ## partner
                <div class="act_as_cell" style="width: 280px;"></div>
                ## label
                <div class="act_as_cell" style="width: 310px;"></div>
                ## debit
                <div class="act_as_cell amount">${formatLang(account_total_debit) | amount }</div>
                ## credit
                <div class="act_as_cell amount">${formatLang(account_total_credit) | amount }</div>
                %if amount_currency(data):
                  ## currency balance
                  <div class="act_as_cell amount sep_left"></div>
                  ## currency code
                  <div class="act_as_cell" style="text-align: right; right;"></div>
                %endif
            </div>
        </div>
        %endfor

%if dict_account_summary:
         <br/>
         <br/>

            <div class="account_title" style="width:700px;">
            ${_('Summary by Account')}
            </div>
                <div class="act_as_table list_table" style="width:700px;">
                <div class="act_as_thead">
                    <div class="act_as_row labels">
                        ##Account name
                        <div class="act_as_cell" style="width: 400px; font-weight:bold;">${_('Account')}</div>
                        ## debit
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${_('Debit')}</div>
                        ## credit
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${_('Credit')}</div>
                    </div>
                </div>
                <div class="act_as_tbody">
                    <% tot_debit_acc = tot_credit_acc = 0.0 %>
                    %for account_key in sorted(dict_account_summary, key=lambda a: dict_account_summary[a]['parent_left']):
                    <% account = dict_account_summary[account_key] %>
                    <div class="act_as_row ">
                        ##Account name
                        <div class="act_as_cell" style="width: 400px;">${account['name']}</div>
                        ## debit
                        <div class="act_as_cell amount" style="width: 150px;">${formatLang(account['debit'] or 0.0)}</div>
                        ## credit
                        <div class="act_as_cell amount" style="width: 150px;">${formatLang(account['credit'] or 0.0)}</div>
                        <%
                    tot_debit_acc += account['debit'] or 0.0
                    tot_credit_acc += account['credit'] or 0.0
                    %>
                    </div>

                    %endfor
                </div>

                <div class="act_as_thead">
                    <div class="act_as_row labels">
                        ##Account name
                        <div class="act_as_cell" style="width: 400px; font-weight:bold;">${_('Total:')}</div>
                        ## debit
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${formatLang(tot_debit_acc or 0.0)}</div>
                        ## credit
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${formatLang(tot_credit_acc or 0.0)}</div>
                    </div>
                </div>

            </div>
         %endif


         %if dict_taxcode_summary:
         <br/>
         <br/>

            <div class="account_title" style="width:700px;">
            ${_('Summary by Tax Code')}
            </div>
                <div class="act_as_table list_table" style="width:700px;">
                <div class="act_as_thead">
                    <div class="act_as_row labels">
                        ##tax code name
                        <div class="act_as_cell" style="width:150px; font-weight:bold;">${_('Tax Code')}</div>
                        <div class="act_as_cell" style="width:400px; font-weight:bold;">${_('Tax Name')}</div>
                        ## tax amount
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${_('Amount')}</div>
                    </div>
                </div>
                <div class="act_as_tbody">
                    <% tot_amount = 0.0 %>
                    %for tax_key in sorted(dict_taxcode_summary):
                    <% tax_code = dict_taxcode_summary[tax_key] %>
                    <div class="act_as_row ">
                        ##taxcode name
                        <div class="act_as_cell" style="width:150px;">${tax_code['code']}</div>
                        <div class="act_as_cell" style="width:400px;">${tax_code['name']}</div>
                        ## tax amount
                        <div class="act_as_cell amount" style="width: 150px;">${formatLang(tax_code['amount'] or '')}</div>
                        <%
                    tot_amount += tax_code['amount'] or 0.0
                    %>
                    </div>

                    %endfor
                </div>

                <div class="act_as_thead">
                    <div class="act_as_row labels">
                        ##tax code name
                        <div class="act_as_cell" style="width:150px; font-weight:bold;">${_('Total:')}</div>
                        <div class="act_as_cell" style="width:400px;"></div>
                        ## tax amount
                        <div class="act_as_cell amount" style="width: 150px;font-weight:bold;">${formatLang(tot_amount or 0.0)}</div>
                    </div>
                </div>

            </div>
         %endif
    </body>
</html>
