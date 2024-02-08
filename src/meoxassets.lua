local assets = require "assetloader"

local MeoxAssets = {}
MeoxAssets.__index = MeoxAssets

function MeoxAssets:init()
	local meox = Model:fromLoader("meox.iqm")
	self.meox = meox
	self.meoxi = ModelInstance:newInstance(meox)
	self.meoxi.props.model_i_contour_flag = true

	local bowl = Model:fromLoader("bowl.iqm")
	self.bowl = bowl
	self.bowli = ModelInstance:newInstance(bowl)
	self.bowli.props.model_i_contour_flag = true

	self.icon_sleep = Model:fromLoader("iconsleep.iqm")
	self.icon_eat = Model:fromLoader("iconeat.iqm")
	self.icon_pet = Model:fromLoader("iconpet.iqm")
	self.icon_misc = Model:fromLoader("iconmisc.iqm")
	self.icon_back = Model:fromLoader("iconback.iqm")

	self.icon_hueplus  = Model:fromLoader("hueplus.iqm")
	self.icon_hueminus = Model:fromLoader("hueminus.iqm")
	self.icon_satplus  = Model:fromLoader("satplus.iqm")
	self.icon_satminus = Model:fromLoader("satminus.iqm")
	self.icon_lumplus  = Model:fromLoader("lumplus.iqm")
	self.icon_lumminus = Model:fromLoader("lumminus.iqm")

	self.iconi = ModelInstance:newInstance(self.icon_back)
	self.iconi:setScale{16,16,16}
	self.iconi.props.model_i_contour_flag = true

	self.case_img = assets:getTextureReference("case.png")
	self.button_l1_img = assets:getTextureReference("l1.png")
	self.button_m1_img = assets:getTextureReference("m1.png")
	self.button_r1_img = assets:getTextureReference("r1.png")
	self.button_l2_img = assets:getTextureReference("l2.png")
	self.button_m2_img = assets:getTextureReference("m2.png")
	self.button_r2_img = assets:getTextureReference("r2.png")

	self.button_l_rect = {30 ,360,64,58}
	self.button_m_rect = {113,356,63,64}
	self.button_r_rect = {192,369,63,54}

	self.case_img = assets:getTextureReference("case.png")
end

return MeoxAssets

