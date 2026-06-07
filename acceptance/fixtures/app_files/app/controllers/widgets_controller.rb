# frozen_string_literal: true

class WidgetsController < ApplicationController
  def index
    widgets = Queries::WidgetsQuery.new
                                   .order(sort_field: :name, sort_direction: :asc)
                                   .page(page)
                                   .per(per)
                                   .all
    render json: widgets.map { |widget| { id: widget.id, name: widget.name } }
  end

  def create
    UserStories::Widgets::Register.call(
      name: params[:name].to_s,
      listener: self,
      on_success: :create_succeeded,
      on_failure: :create_failed,
    )
  end

  def create_succeeded(widget:)
    render json: { id: widget.id, name: widget.name }, status: :created
  end

  def create_failed(errors: nil)
    render json: { errors: Array(errors) }, status: :unprocessable_entity
  end

  private

  def page
    params.fetch(:page, 1).to_i
  end

  def per
    params.fetch(:per, 2).to_i
  end
end
