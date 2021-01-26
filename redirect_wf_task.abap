*&---------------------------------------------------------------------*
*&      Переадресация задачи Workflow
*&---------------------------------------------------------------------*

FORM redirect_wf_task USING p_wi_id  TYPE sww_wiid
                            p_login  TYPE xubname.
  DATA: lv_answer,
        ls_workitem TYPE swlc_workitem.

  CALL FUNCTION 'SWL_WI_READ'
    EXPORTING
      wi_id              = p_wi_id
    CHANGING
      workitem           = ls_workitem
    EXCEPTIONS
      workitem_not_found = 1
      OTHERS             = 2.

  IF sy-subrc EQ 0.
*    Проверить, что задача не была уже переадресована
    IF ls_workitem-wi_forw_by IS NOT INITIAL.
      MESSAGE |ЭПО № { p_wi_id } уже был переадресован| TYPE 'S'.
      RETURN.
    ENDIF.

*     в диалоговом режиме выводим окно с подтверждением переадресации задачи
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = |Переадресовать ЭПО № { p_wi_id } ({ ls_workitem-wi_text })?|
        text_button_1         = 'Да'
        text_button_2         = 'Нет'
        display_cancel_button = 'X'
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        OTHERS                = 0.

    IF lv_answer = '1'.
*     переадресация задачи
      DATA:
        ls_message_line   TYPE swr_messag,
        lt_message_lines  TYPE sapi_msg_lines,
        lt_message_struct TYPE sapi_msg_struc,

        lv_new_status     TYPE swr_wistat,
        lv_return_code    TYPE syst_subrc.

      CALL FUNCTION 'SAP_WAPI_FORWARD_WORKITEM'
        EXPORTING
          workitem_id    = p_wi_id
          user_id        = p_login
        IMPORTING
          new_status     = lv_new_status
          return_code    = lv_return_code
        TABLES
          message_lines  = lt_message_lines
          message_struct = lt_message_struct.

      TRY.
          lv_message = lt_message_lines[ 1 ]-line.
          MESSAGE lv_message TYPE 'S'.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

    ELSEIF lv_answer = '2'.
*       пользователь отменил переадресацию данного ЭПО
    ELSEIF lv_answer = 'A'.
      LEAVE PROGRAM.
    ENDIF.

  ENDIF.
ENDFORM.